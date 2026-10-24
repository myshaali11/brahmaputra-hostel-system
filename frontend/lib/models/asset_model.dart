class AssetModel {
  final int id;
  final int locationId;
  final String name;
  final String status; // WORKING, COMPLAINT_RAISED, DAMAGED
  final String? comment;
  final String? lastCheckedAt;

  AssetModel({
    required this.id,
    required this.locationId,
    required this.name,
    required this.status,
    this.comment,
    this.lastCheckedAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      locationId: json['locationId'] is int
          ? json['locationId']
          : int.parse(json['locationId']?.toString() ?? '0'),
      name: json['name'] ?? '',
      status: json['status'] ?? 'WORKING',
      comment: json['comment'],
      lastCheckedAt: json['lastCheckedAt'],
    );
  }

  bool get isWorking => status == 'WORKING';
  bool get hasComplaint => status == 'COMPLAINT_RAISED';
  bool get isDamaged => status == 'DAMAGED';
}
