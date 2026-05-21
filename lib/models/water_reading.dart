class WaterReading {
  final double ph;
  final double temperature;
  final double turbidity;
  final double salinity;
  final double ammonia;
  final double lat;
  final double lng;
  final String locationType;
  final DateTime timestamp;

  WaterReading({
    required this.ph,
    required this.temperature,
    required this.turbidity,
    required this.salinity,
    required this.ammonia,
    required this.lat,
    required this.lng,
    required this.locationType,
    required this.timestamp,
  });
}
