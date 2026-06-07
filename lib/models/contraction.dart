import 'package:flutter/material.dart';

enum PainLevel {
  none(0, 'Sem dor', Icons.sentiment_very_satisfied_rounded, Color(0xFF4CAF50)),
  mild(1, 'Dor leve', Icons.sentiment_satisfied_rounded, Color(0xFFFFC107)),
  moderate(2, 'Dor moderada', Icons.sentiment_dissatisfied_rounded, Color(0xFFFF9800)),
  strong(3, 'Dor forte', Icons.sentiment_very_dissatisfied_rounded, Color(0xFFF44336));

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const PainLevel(this.value, this.label, this.icon, this.color);

  static PainLevel? fromValue(int? value) {
    if (value == null) return null;
    for (final level in PainLevel.values) {
      if (level.value == value) return level;
    }
    return null;
  }
}

class Contraction {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final PainLevel? painLevel;

  Contraction({
    this.id,
    required this.startTime,
    this.endTime,
    this.painLevel,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  Contraction copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    PainLevel? painLevel,
  }) {
    return Contraction(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      painLevel: painLevel ?? this.painLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'pain_level': painLevel?.value,
    };
  }

  factory Contraction.fromMap(Map<String, dynamic> map) {
    return Contraction(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      painLevel: PainLevel.fromValue(map['pain_level'] as int?),
    );
  }
}
