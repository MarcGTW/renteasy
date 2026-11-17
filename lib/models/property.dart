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