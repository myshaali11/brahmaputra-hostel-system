class UserModel {
  final String username;
  final String fullName;
  final String? email;
  final String role; // MANAGER, STAFF, STUDENT
  final int? allocatedRoomId;
  final String? roomName;

  UserModel({
    required this.username,
    required this.fullName,
    this.email,
    required this.role,
    this.allocatedRoomId,
    this.roomName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      allocatedRoomId: json['allocatedRoomId'] is int
          ? json['allocatedRoomId']
          : (json['allocatedRoomId'] != null
              ? int.tryParse(json['allocatedRoomId'].toString())
              : null),
      roomName: json['roomName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'fullName': fullName,
      'email': email,
      'role': role,
      'allocatedRoomId': allocatedRoomId,
      'roomName': roomName,
    };
  }
}
