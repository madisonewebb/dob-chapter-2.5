class FilamentModel {
  final String id;
  final String name;
  final String type;
  final String brand;
  final double minTemp;
  final double maxTemp;
  final double price;

  FilamentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.brand,
    required this.minTemp,
    required this.maxTemp,
    required this.price,
  });

  // Factory constructor to create a FilamentModel from Firestore data
  factory FilamentModel.fromMap(Map<String, dynamic> data, String id) {
    return FilamentModel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      brand: data['brand'] ?? '',
      minTemp: (data['minTemp'] ?? 0).toDouble(),
      maxTemp: (data['maxTemp'] ?? 0).toDouble(),
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  // Method to convert FilamentModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'brand': brand,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'price': price,
    };
  }
}
