import '../models/water_reading.dart';

final List<WaterReading> mockWaterData = [
  WaterReading(
    ph: 7.6,
    temperature: 30.2,
    turbidity: 3.8,
    dissolvedOxygen: 6.1,
    ammonia: 0.04,
    lat: 15.401,
    lng: 73.812,
    locationType: 'Sea Cage',
    timestamp: DateTime.now(),
  ),
  WaterReading(
    ph: 9.1,
    temperature: 34.0,
    turbidity: 6.2,
    dissolvedOxygen: 3.4,
    ammonia: 0.12,
    lat: 15.392,
    lng: 73.805,
    locationType: 'Khazan',
    timestamp: DateTime.now(),
  ),
];
