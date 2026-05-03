import '../entities/dog_breed_info.dart';
import '../repositories/dog_api_repository.dart';

class GetDogInfoUseCase {
  final DogApiRepository repository;

  GetDogInfoUseCase(this.repository);

  Future<DogBreedInfo?> call(String breedName) {
    return repository.getBreedInfo(breedName);
  }
}