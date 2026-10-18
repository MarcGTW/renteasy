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
}

class Booking {
  final String id;
  final String propertyTitle;
  final String date;
  final String time;
  final String status;

  const Booking({
    required this.id,
    required this.propertyTitle,
    required this.date,
    required this.time,
    required this.status,
  });
}

const mockProperties = [
  Property(id: '1', title: '2-комнатная новостройка в Центре', address: 'г. Кишинёв, ул. Лев Толстой 24', price: 550.0, type: 'Аренда', rooms: 2, area: 65.0, rating: 4.9, agentName: 'Алена Русу', agentPhone: '+373 69 112233', imageInitials: 'К2'),
  Property(id: '2', title: 'Пентхаус с видом на парк', address: 'г. Кишинёв, ул. Мирон Костин 12', price: 120000.0, type: 'Продажа', rooms: 3, area: 110.0, rating: 5.0, agentName: 'Максим Гросу', agentPhone: '+373 79 445566', imageInitials: 'П3'),
  Property(id: '3', title: 'Уютная студия на Рышкановке', address: 'г. Кишинёв, Московский проспект 8', price: 350.0, type: 'Аренда', rooms: 1, area: 38.0, rating: 4.7, agentName: 'Ирина Чебан', agentPhone: '+373 68 778899', imageInitials: 'С1'),
  Property(id: '4', title: '3-комнатная квартира на Ботанике', address: 'г. Кишинёв, бульвар Дачия 20', price: 85000.0, type: 'Продажа', rooms: 3, area: 82.0, rating: 4.8, agentName: 'Дмитрий Урсу', agentPhone: '+373 60 223344', imageInitials: 'К3'),
  Property(id: '5', title: 'Современные апартаменты Буюканы', address: 'г. Кишинёв, ул. Альба-Юлия 75', price: 480.0, type: 'Аренда', rooms: 2, area: 58.0, rating: 4.6, agentName: 'Алена Русу', agentPhone: '+373 69 112233', imageInitials: 'А2'),
  Property(id: '6', title: 'Таунхаус с террасой Чеканы', address: 'г. Кишинёв, ул. Мирча чел Бэтрын 32', price: 145000.0, type: 'Продажа', rooms: 4, area: 140.0, rating: 4.9, agentName: 'Максим Гросу', agentPhone: '+373 79 445566', imageInitials: 'Т4'),
];

const mockBookings = [
  Booking(id: 'BK-201', propertyTitle: '2-комнатная новостройка в Центре', date: '10.10.2026', time: '14:00', status: 'Подтверждено'),
  Booking(id: 'BK-202', propertyTitle: 'Уютная студия на Рышкановке', date: '12.10.2026', time: '16:30', status: 'В ожидании'),
  Booking(id: 'BK-203', propertyTitle: '3-комнатная квартира на Ботанике', date: '05.10.2026', time: '11:00', status: 'Завершено'),
  Booking(id: 'BK-204', propertyTitle: 'Пентхаус с видом на парк', date: '28.09.2026', time: '15:00', status: 'Отменено'),
  Booking(id: 'BK-205', propertyTitle: 'Современные апартаменты Буюканы', date: '20.09.2026', time: '18:00', status: 'Завершено'),
  Booking(id: 'BK-206', propertyTitle: 'Таунхаус с террасой Чеканы', date: '15.09.2026', time: '12:00', status: 'Завершено'),
];