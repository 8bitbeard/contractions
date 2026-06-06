class Contraction {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;

  Contraction({
    this.id,
    required this.startTime,
    this.endTime,
  });

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  Contraction copyWith({int? id, DateTime? startTime, DateTime? endTime}) {
    return Contraction(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
    };
  }

  factory Contraction.fromMap(Map<String, dynamic> map) {
    return Contraction(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
    );
  }
}
