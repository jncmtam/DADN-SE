class CageDetail {
  final String id; // UUID
  final String name; // Cage name
  final String status; // Enum: "on" or "off"
  final DateTime createdAt; // Timestamp
  final DateTime updatedAt; // Timestamp

  CageDetail({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create a Cage object from JSON
  factory CageDetail.fromJson(Map<String, dynamic> json) {
    return CageDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Method to convert a Cage object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}