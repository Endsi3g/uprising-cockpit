class Client {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'created_at': createdAt.toIso8601String(),
      };
}
