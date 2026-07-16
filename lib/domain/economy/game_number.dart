import 'dart:math' as math;

/// A non-negative, base-10 floating-point value for an idle-game economy.
///
/// Values are normalized as `mantissa * 10^exponent`, where zero is always
/// represented by `(0, 0)` and non-zero mantissas are in the range [1, 10).
final class GameNumber implements Comparable<GameNumber> {
  const GameNumber._(this.mantissa, this.exponent);

  factory GameNumber.fromNum(num value) {
    final raw = value.toDouble();
    if (raw.isNaN || raw <= 0) {
      return zero;
    }
    if (!raw.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    final exponent = (math.log(raw) / math.ln10).floor();
    return GameNumber.fromParts(raw / math.pow(10.0, exponent), exponent);
  }

  factory GameNumber.fromParts(double mantissa, int exponent) {
    if (mantissa.isNaN || !mantissa.isFinite) {
      throw ArgumentError.value(mantissa, 'mantissa', 'must be finite');
    }
    if (mantissa <= 0) {
      return zero;
    }
    final shift = (math.log(mantissa) / math.ln10).floor();
    var normalized = mantissa / math.pow(10.0, shift);
    var normalizedExponent = exponent + shift;
    if (normalized >= 10) {
      normalized /= 10;
      normalizedExponent += 1;
    } else if (normalized < 1) {
      normalized *= 10;
      normalizedExponent -= 1;
    }
    return GameNumber._(normalized, normalizedExponent);
  }

  factory GameNumber.fromJson(Object? value) {
    if (value is num) {
      return GameNumber.fromNum(value);
    }
    if (value is Map) {
      final mantissa = value['m'];
      final exponent = value['e'];
      if (mantissa is num && exponent is num) {
        return GameNumber.fromParts(mantissa.toDouble(), exponent.toInt());
      }
    }
    return zero;
  }

  static const zero = GameNumber._(0, 0);
  static const one = GameNumber._(1, 0);

  final double mantissa;
  final int exponent;

  bool get isZero => mantissa == 0;
  bool get isFinite => true;

  GameNumber operator +(Object other) {
    final rhs = _coerce(other);
    if (isZero) return rhs;
    if (rhs.isZero) return this;
    final difference = exponent - rhs.exponent;
    if (difference >= 16) return this;
    if (difference <= -16) return rhs;
    if (difference >= 0) {
      return GameNumber.fromParts(
        mantissa + rhs.mantissa * math.pow(10.0, -difference),
        exponent,
      );
    }
    return GameNumber.fromParts(
      mantissa * math.pow(10.0, difference) + rhs.mantissa,
      rhs.exponent,
    );
  }

  GameNumber operator -(Object other) {
    final rhs = _coerce(other);
    if (rhs.isZero) return this;
    if (compareTo(rhs) <= 0) return zero;
    final difference = exponent - rhs.exponent;
    if (difference >= 16) return this;
    return GameNumber.fromParts(
      mantissa - rhs.mantissa * math.pow(10.0, -difference),
      exponent,
    );
  }

  GameNumber operator *(Object other) {
    final rhs = _coerce(other);
    if (isZero || rhs.isZero) return zero;
    return GameNumber.fromParts(
      mantissa * rhs.mantissa,
      exponent + rhs.exponent,
    );
  }

  GameNumber operator /(Object other) {
    final rhs = _coerce(other);
    if (rhs.isZero) throw UnsupportedError('Cannot divide by zero.');
    if (isZero) return zero;
    return GameNumber.fromParts(
      mantissa / rhs.mantissa,
      exponent - rhs.exponent,
    );
  }

  bool operator <(Object other) => compareTo(_coerce(other)) < 0;
  bool operator <=(Object other) => compareTo(_coerce(other)) <= 0;
  bool operator >(Object other) => compareTo(_coerce(other)) > 0;
  bool operator >=(Object other) => compareTo(_coerce(other)) >= 0;

  @override
  int compareTo(GameNumber other) {
    if (isZero) return other.isZero ? 0 : -1;
    if (other.isZero) return 1;
    final exponentComparison = exponent.compareTo(other.exponent);
    return exponentComparison != 0
        ? exponentComparison
        : mantissa.compareTo(other.mantissa);
  }

  double toDouble() {
    if (isZero) return 0;
    if (exponent > 308) return double.infinity;
    if (exponent < -324) return 0;
    return mantissa * math.pow(10.0, exponent);
  }

  Map<String, Object> toJson() => {'m': mantissa, 'e': exponent};

  static GameNumber _coerce(Object value) {
    if (value is GameNumber) return value;
    if (value is num) return GameNumber.fromNum(value);
    throw ArgumentError.value(value, 'value', 'must be num or GameNumber');
  }

  @override
  bool operator ==(Object other) => other is GameNumber
      ? mantissa == other.mantissa && exponent == other.exponent
      : other is num && compareTo(GameNumber.fromNum(other)) == 0;

  @override
  int get hashCode => Object.hash(mantissa, exponent);

  @override
  String toString() => isZero ? '0' : '${mantissa}e$exponent';
}
