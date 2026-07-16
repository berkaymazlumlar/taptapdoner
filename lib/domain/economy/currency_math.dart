import 'package:taptapdoner/domain/economy/game_number.dart';

abstract final class CurrencyMath {
  static const int legacyInt64MaxCurrency = 0x7FFFFFFFFFFFFFFF;

  static GameNumber value(Object? value) => value is GameNumber
      ? value
      : GameNumber.fromNum(value is num ? value : 0);

  static dynamic clamp(Object? value) {
    if (value is GameNumber) return value;
    if (value is num) {
      if (value.isNaN || value <= 0) return 0;
      return value.isFinite ? value : double.maxFinite;
    }
    return 0;
  }

  static dynamic add(Object value, Object amount) {
    if (value is num && amount is num) {
      if (value is int &&
          amount is int &&
          amount > 0 &&
          value > legacyInt64MaxCurrency - amount) {
        return CurrencyMath.value(value) + CurrencyMath.value(amount);
      }
      final result = value + amount;
      if (result.isFinite) return result <= 0 ? 0 : result;
    }
    return CurrencyMath.value(value) + CurrencyMath.value(amount);
  }

  static dynamic subtract(Object value, Object amount) {
    if (value is num && amount is num) {
      final result = value - amount;
      return result <= 0 ? 0 : result;
    }
    return CurrencyMath.value(value) - CurrencyMath.value(amount);
  }

  static Object toJson(Object value) =>
      value is GameNumber ? value.toJson() : value;

  static double floorDouble(double value) =>
      value.isFinite && value > 0 ? value.floorToDouble() : 0;

  static double roundDouble(double value) =>
      value.isFinite && value > 0 ? value.roundToDouble() : 0;

  static int floorInt(double value) {
    if (value.isNaN || value <= 0) return 0;
    if (!value.isFinite || value >= legacyInt64MaxCurrency.toDouble()) {
      return legacyInt64MaxCurrency;
    }
    return value.floor();
  }

  static int roundInt(double value) {
    if (value.isNaN || value <= 0) return 0;
    if (!value.isFinite || value >= legacyInt64MaxCurrency.toDouble()) {
      return legacyInt64MaxCurrency;
    }
    return value.round();
  }

  static double clampDouble(double value) {
    if (value.isNaN || value <= 0) return 0;
    return value.isFinite ? value : double.maxFinite;
  }
}
