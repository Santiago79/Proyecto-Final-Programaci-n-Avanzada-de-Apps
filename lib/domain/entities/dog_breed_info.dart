class DogBreedInfo {
  final String name;
  final String origin;
  final String temperament;
  final String lifeSpan;
  final String? imageUrl;

  DogBreedInfo({
    required this.name,
    required this.origin,
    required this.temperament,
    required this.lifeSpan,
    this.imageUrl,
  });
}