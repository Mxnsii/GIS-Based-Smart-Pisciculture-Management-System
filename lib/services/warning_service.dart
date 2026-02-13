enum WaterStatus { safe, warning, critical }

class WarningService {
  static WaterStatus evaluate(WaterReading data) {
    if (data.ph < 6.5 || data.ph > 8.5) return WaterStatus.warning;
    if (data.temperature > 32) return WaterStatus.warning;
    if (data.dissolvedOxygen < 4) return WaterStatus.critical;
    if (data.ammonia > 0.1) return WaterStatus.critical;

    return WaterStatus.safe;
  }
}
