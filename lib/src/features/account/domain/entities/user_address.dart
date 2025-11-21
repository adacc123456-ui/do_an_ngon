class UserAddress {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String street;
  final String ward;
  final String district;
  final String city;
  final String? note;
  final bool isDefault;

  const UserAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.ward,
    required this.district,
    required this.city,
    this.note,
    this.isDefault = false,
  });

  String get fullAddress {
    return '$street, $ward, $district, $city';
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Địa chỉ',
      recipientName: json['recipientName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      ward: json['ward']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      note: json['note']?.toString(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'street': street,
      'ward': ward,
      'district': district,
      'city': city,
      if (note != null) 'note': note,
      'isDefault': isDefault,
    };
  }
}

