import '../entities/care_video.dart';

abstract class YouTubeRepository {
  Future<CareVideo?> getCareVideoForBreed(String breedName);
}