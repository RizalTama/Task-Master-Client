// A simple model class to represent the application's user.
class User {
  final String uid;
  final String email;

  User({
    required this.uid,
    required this.email,
  });

  // A factory constructor for creating a new User instance from a map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      email: json['email'],
    );
  }
}
