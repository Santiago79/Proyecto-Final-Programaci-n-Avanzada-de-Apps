import '../entities/dog_breed_info.dart';

abstract class DogApiRepository {
  Future<DogBreedInfo?> getBreedInfo(String breedName);
}