class Craving {
  final DateTime timestamp;
  final int intensity; // 1-5
  final String trigger; // e.g., after meal, stress
  final String coping; // e.g., deep breathing
  final String? note;

  Craving({
    required this.timestamp,
    required this.intensity,
    required this.trigger,
    required this.coping,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'intensity': intensity,
        'trigger': trigger,
        'coping': coping,
        'note': note,
      };

  factory Craving.fromMap(Map<String, dynamic> map) => Craving(
        timestamp: DateTime.parse(map['timestamp'] as String),
        intensity: map['intensity'] as int,
        trigger: map['trigger'] as String,
        coping: map['coping'] as String,
        note: map['note'] as String?,
      );
}
