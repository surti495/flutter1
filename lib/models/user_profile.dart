class UserProfile {
  final int id;
  final String email;
  final String name;
  final String? profilePicture;
  final String? profilePictureFullUrl; // Add this field

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.profilePicture,
    this.profilePictureFullUrl, // Add this
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      profilePicture: json['profile_picture'],
      profilePictureFullUrl: json['profile_picture_full_url'] as String?,
    );
  }
}
