class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<String> getCurrentLocation() async {
    // Simulate location fetch
    await Future.delayed(Duration(seconds: 1));
    return "Current Location, City";
  }

  Future<List<String>> getRecommendedProviders() async {
    await Future.delayed(Duration(seconds: 1));
    return ["Provider A", "Provider B", "Provider C"];
  }
}