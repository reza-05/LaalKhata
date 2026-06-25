class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.department,
    this.avatarUrl,
    this.studentId,
    this.batch,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String department;
  final String? avatarUrl;
  final String? studentId;
  final String? batch;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String? ?? 'IUT Student',
      role: map['role'] as String? ?? 'Student',
      department: map['department'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      studentId: map['student_id'] as String?,
      batch: map['batch'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'department': department,
      'avatar_url': avatarUrl,
      'student_id': studentId,
      'batch': batch,
    };
  }
}
