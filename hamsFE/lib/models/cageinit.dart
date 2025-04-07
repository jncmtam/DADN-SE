class CageInit {
  final String id; // UUID
  final String name; // Cage name
  int numDevice; // Number of devices in the cage
  String status; // Status of the cage ("on" or "off")

  CageInit({
    required this.id,
    required this.name,
    required this.numDevice,
    required this.status,
  });

  // Factory constructor to create a CageInit object from JSON
  factory CageInit.fromJson(Map<String, dynamic> json) {
    return CageInit(
      id: json['id'] as String,
      name: json['name'] as String,
      numDevice: json['num_device'] as int,
      status: json['status'] as String,
    );
  }

  // Method to convert a CageInit object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'num_device': numDevice,
      'status': status,
    };
  }
}