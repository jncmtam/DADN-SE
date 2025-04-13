class CageInit {
  final String id;
  final String name;
  int numDevice;
  String status;

  CageInit({
    required this.id,
    required this.name,
    this.numDevice = 0,
    this.status = 'off',
  });

  // Factory constructor to create a CageInit object from JSON
  factory CageInit.fromJson(Map<String, dynamic> json) {
    // For initial creation response that only includes id and name
    if (json.containsKey('message')) {
      return CageInit(
        id: json['id'] as String,
        name: json['name'] as String,
      );
    }
    
    // For regular cage data that includes all fields
    return CageInit(
      id: json['id'] as String,
      name: json['name'] as String,
      numDevice: json['num_device'] != null ? json['num_device'] as int : 0,
      status: json['status'] ?? 'off',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'num_device': numDevice,
      'status': status,
    };
  }
}