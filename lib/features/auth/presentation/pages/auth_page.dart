import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/password_recovery_signal.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/auth_validator.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../widgets/laalkhata_mark.dart';
import 'reset_password_request_page.dart';

enum _AccountRole {
  student('Student'),
  faculty('Faculty'),
  staff('Staff');

  const _AccountRole(this.label);

  final String label;
}

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.setupNotice});

  final String? setupNotice;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _batchController = TextEditingController();

  bool _isSignUp = false;
  bool _passwordVisible = false;
  _AccountRole _role = _AccountRole.student;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordHints);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordHints);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _refreshPasswordHints() {
    if (_isSignUp && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LaalKhataMark(),
                      SizedBox(height: compact ? 22 : 28),
                      _AuthPanel(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isSignUp ? 'Create account' : 'Login',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSignUp
                                    ? 'Register with your verified IUT identity.'
                                    : 'Use your IUT mail and password to continue.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.mutedInk,
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              if (widget.setupNotice != null) ...[
                                _MessageBanner(
                                  message: widget.setupNotice!,
                                  color: widget.setupNotice!
                                          .toLowerCase()
                                          .contains('confirmed')
                                      ? AppColors.positive
                                      : AppColors.warning,
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (authState.message != null) ...[
                                _MessageBanner(
                                  message: authState.message!,
                                  color: authState.status == AuthStatus.error
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (_isSignUp) ...[
                                _TextField(
                                  controller: _nameController,
                                  label: 'Full name',
                                  icon: Icons.badge_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) =>
                                      AuthValidator.validateDisplayName(
                                    value ?? '',
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              _TextField(
                                controller: _emailController,
                                label: 'IUT email',
                                hint: 'name@iut-dhaka.edu',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    AuthValidator.validateIutEmail(value ?? ''),
                              ),
                              const SizedBox(height: 14),
                              if (_isSignUp) ...[
                                DropdownButtonFormField<_AccountRole>(
                                  initialValue: _role,
                                  borderRadius: BorderRadius.circular(16),
                                  decoration: const InputDecoration(
                                    labelText: 'Account type',
                                    prefixIcon: Icon(Icons.school_outlined),
                                  ),
                                  items: _AccountRole.values
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (role) {
                                    if (role == null) return;
                                    setState(() {
                                      _role = role;
                                      if (role == _AccountRole.staff) {
                                        _departmentController.clear();
                                      }
                                    });
                                  },
                                ),
                                if (_role != _AccountRole.staff) ...[
                                  const SizedBox(height: 14),
                                  _TextField(
                                    controller: _departmentController,
                                    label: 'Department',
                                    icon: Icons.apartment_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        AuthValidator.validateRequired(
                                      value ?? '',
                                      'Department',
                                    ),
                                  ),
                                ],
                                if (_role == _AccountRole.student) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _TextField(
                                          controller: _studentIdController,
                                          label: 'Student ID',
                                          icon: Icons
                                              .confirmation_number_outlined,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) =>
                                              AuthValidator.validateRequired(
                                            value ?? '',
                                            'Student ID',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _TextField(
                                          controller: _batchController,
                                          label: 'Batch',
                                          icon: Icons.groups_2_outlined,
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) =>
                                              AuthValidator.validateRequired(
                                            value ?? '',
                                            'Batch',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 14),
                              ],
                              _TextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_passwordVisible,
                                suffixIcon: IconButton(
                                  tooltip: _passwordVisible
                                      ? 'Hide password'
                                      : 'Show password',
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                validator: (value) {
                                  if (!_isSignUp) {
                                    return AuthValidator.validatePassword(
                                      value ?? '',
                                    );
                                  }
                                  return AuthValidator.validateStrongPassword(
                                    value ?? '',
                                    name: _nameController.text,
                                    email: _emailController.text,
                                    studentId: _studentIdController.text,
                                  );
                                },
                              ),
                              if (!_isSignUp) ...[
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: isLoading
                                        ? null
                                        : _openResetPasswordPage,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: const VisualDensity(
                                        horizontal: -2,
                                        vertical: -2,
                                      ),
                                    ),
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                              ],
                              if (_isSignUp) ...[
                                const SizedBox(height: 10),
                                _PasswordHint(
                                    password: _passwordController.text),
                              ],
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                child: isLoading
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isSignUp ? 'Create account' : 'Login',
                                      ),
                              ),
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isSignUp = !_isSignUp;
                                        });
                                      },
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account? Login'
                                      : 'New to LaalKhata? Create an account',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    PasswordRecoverySignal.clearAuthNotice();
    final controller = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      controller.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
        role: _role.label,
        department:
            _role == _AccountRole.staff ? '' : _departmentController.text,
        studentId:
            _role == _AccountRole.student ? _studentIdController.text : null,
        batch: _role == _AccountRole.student ? _batchController.text : null,
      );
      return;
    }

    controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  void _openResetPasswordPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ResetPasswordRequestPage(),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          const BoxShadow(
            color: AppColors.subtleShadow,
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final checks = [
      _PasswordCheck('8+ characters', password.length >= 8),
      _PasswordCheck('Uppercase', RegExp(r'[A-Z]').hasMatch(password)),
      _PasswordCheck('Lowercase', RegExp(r'[a-z]').hasMatch(password)),
      _PasswordCheck('Number', RegExp(r'\d').hasMatch(password)),
      _PasswordCheck(
        'Special',
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`/\\;[\]]').hasMatch(password),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: checks
          .map(
            (check) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: check.passed
                    ? AppColors.income.withValues(alpha: 0.1)
                    : AppColors.line.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                check.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          check.passed ? AppColors.income : AppColors.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PasswordCheck {
  const _PasswordCheck(this.label, this.passed);

  final String label;
  final bool passed;
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.color,
  });

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
