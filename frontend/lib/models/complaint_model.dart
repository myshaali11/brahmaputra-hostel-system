class ComplaintModel {
  final int id;
  final String? ivrsNumber;
  final int locationId;
  final String? locationName;
  final int? assetId;
  final String? assetName;
  final String title;
  final String description;
  final String status; // OPEN, IN_PROGRESS, RESOLVED, CLOSED
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final String? reportedBy;
  final String? createdAt;
  final String? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;

  ComplaintModel({
    required this.id,
    this.ivrsNumber,
    required this.locationId,
    this.locationName,
    this.assetId,
    this.assetName,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.reportedBy,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      ivrsNumber: json['ivrsNumber'],
      locationId: json['locationId'] is int
          ? json['locationId']
          : int.parse(json['locationId']?.toString() ?? '0'),
      locationName: json['locationName'],
      assetId: json['assetId'] != null
          ? (json['assetId'] is int
              ? json['assetId']
              : int.tryParse(json['assetId'].toString()))
          : null,
      assetName: json['assetName'],
      title: json['title'] ?? 'Issue',
      description: json['description'] ?? '',
      status: json['status'] ?? 'OPEN',
      priority: json['priority'] ?? 'MEDIUM',
      reportedBy: json['reportedBy'],
      createdAt: json['createdAt'],
      resolvedAt: json['resolvedAt'],
      resolvedBy: json['resolvedBy'],
      resolutionNotes: json['resolutionNotes'],
    );
  }

  String get displayIvrsNumber => ivrsNumber ?? 'TT$id';
  String get displayLocationName => locationName ?? 'Location #$locationId';

  bool get isOpen => status == 'OPEN';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED' || status == 'CLOSED';
}
