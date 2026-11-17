
class Booking {
  final String id;
  final String propertyTitle;
  final String name;
  final String phone;
  final String date;
  final String time;
  final String status;

  const Booking({
    required this.id,
    required this.propertyTitle,
    required this.name,
    required this.phone,
    required this.date,
    required this.time,
    required this.status,
  });

  Booking copyWith({
    String? id,
    String? propertyTitle,
    String? name,
    String? phone,
    String? date,
    String? time,
    String? status,
  }) {
    return Booking(
      id: id ?? this.id,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
