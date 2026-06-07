enum PainLevel {
  none(0, 'Sem dor'),
  mild(1, 'Dor leve'),
  moderate(2, 'Dor moderada'),
  strong(3, 'Dor forte');

  final int value;
  final String label;
  const PainLevel(this.value, this.label);

  static PainLevel? fromValue(int? value) {
    if (value == null) return null;
    return PainLevel.values.firstWhere((e) => e.value == value);
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
