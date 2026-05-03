import '../entities/care_video.dart';
import '../repositories/youtube_repository.dart';

class GetCareVideoUseCase {
  final YouTubeRepository repository;

  GetCareVideoUseCase(this.repository);

  Future<CareVideo?> call(String breedName) {
    return repository.getCareVideoForBreed(breedName);
  }
}