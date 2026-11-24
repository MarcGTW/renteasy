class Property {
  final String id;
  final String title;
  final String address;
  final double price;
  final String type;
  final int rooms;
  final double area;
  final double rating;
  final String agentName;
  final String agentPhone;
  final String imageInitials;

  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    required this.type,
    required this.rooms,
    required this.area,
    required this.rating,
    required this.agentName,
    required this.agentPhone,
    required this.imageInitials,
  });

  factory Property.fromJson(Map<String, dynamic> j) => Property(
    id: (j['id'] as int).toString(),
    title: j['title'] as String,
    address: j['address'] as String? ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    type: j['type'] as String? ?? 'Аренда',
    rooms: (j['rooms'] as num?)?.toInt() ?? 1,
    area: (j['area'] as num?)?.toDouble() ?? 0,
    rating: (j['rating'] as num?)?.toDouble() ?? 0,
    agentName: j['agentName'] as String? ?? '',
    agentPhone: j['agentPhone'] as String? ?? '',
    imageInitials: j['imageInitials'] as String? ?? '',
  );

  /// Без `id` — идентичность выдаёт сервер.
  Map<String, dynamic> toJson() => {
    'title': title,
    'address': address,
    'price': price,
    'type': type,
    'rooms': rooms,
    'area': area,
    'rating': rating,
    'agentName': agentName,
    'agentPhone': agentPhone,
    'imageInitials': imageInitials,
  };

  Property copyWith({String? id}) {
    return Property(
      id: id ?? this.id,
      title: title,
      address: address,
      price: price,
      type: type,
      rooms: rooms,
      area: area,
      rating: rating,
      agentName: agentName,
      agentPhone: agentPhone,
      imageInitials: imageInitials,
    );
  }
}