class Game {
  final int? id;
  final String title;
  final String image;
  final String description;
  final double price;

  Game({
    this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.price,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Convert price safely whether it's String or num
    final priceRaw = json['price'];
    final double priceValue = priceRaw is String
        ? double.parse(priceRaw)
        : (priceRaw as num).toDouble();
    return Game(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      description: json['description'],
      price: priceValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image': image,
      'description': description,
      'price': price,
    };
  }
}