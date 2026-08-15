class Eintrag {
  final int? id;
  final String userId;
  final int ausbildungsjahr;
  final DateTime vonDatum;
  final DateTime bisDatum;
  final List<String> betriebliches;
  final List<String> schulisches;
  final Map<String, List<String>> schulischesProFach;
  final int pauseMinuten;
  final int krankheitstage;
  final int urlaubstage;
  final String besonderheiten;
  final String notizen;
  final DateTime? updatedAt;

  const Eintrag({
    this.id,
    required this.userId,
    required this.ausbildungsjahr,
    required this.vonDatum,
    required this.bisDatum,
    required this.betriebliches,
    required this.schulisches,
    this.schulischesProFach = const {},
    this.pauseMinuten = 30,
    this.krankheitstage = 0,
    this.urlaubstage = 0,
    this.besonderheiten = '',
    this.notizen = '',
    this.updatedAt,
  });

  Eintrag copyWith({
    int? id,
    String? userId,
    int? ausbildungsjahr,
    DateTime? vonDatum,
    DateTime? bisDatum,
    List<String>? betriebliches,
    List<String>? schulisches,
    Map<String, List<String>>? schulischesProFach,
    int? pauseMinuten,
    int? krankheitstage,
    int? urlaubstage,
    String? besonderheiten,
    String? notizen,
    DateTime? updatedAt,
  }) {
    return Eintrag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ausbildungsjahr: ausbildungsjahr ?? this.ausbildungsjahr,
      vonDatum: vonDatum ?? this.vonDatum,
      bisDatum: bisDatum ?? this.bisDatum,
      betriebliches: betriebliches ?? this.betriebliches,
      schulisches: schulisches ?? this.schulisches,
      schulischesProFach: schulischesProFach ?? this.schulischesProFach,
      pauseMinuten: pauseMinuten ?? this.pauseMinuten,
      krankheitstage: krankheitstage ?? this.krankheitstage,
      urlaubstage: urlaubstage ?? this.urlaubstage,
      besonderheiten: besonderheiten ?? this.besonderheiten,
      notizen: notizen ?? this.notizen,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Eintrag.fromJson(Map<String, dynamic> json) {
    return Eintrag(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      ausbildungsjahr: json['ausbildungsjahr'] as int,
      vonDatum: DateTime.parse(json['von_datum'] as String),
      bisDatum: DateTime.parse(json['bis_datum'] as String),
      betriebliches: List<String>.from(json['betriebliches'] ?? []),
      schulisches: List<String>.from(json['schulisches'] ?? []),
      schulischesProFach: (json['schulisches_pro_fach'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, List<String>.from(v as List))),
      pauseMinuten: json['pause_minuten'] as int? ?? 30,
      krankheitstage: json['krankheitstage'] as int? ?? 0,
      urlaubstage: json['urlaubstage'] as int? ?? 0,
      besonderheiten: json['besonderheiten'] as String? ?? '',
      notizen: json['notizen'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'ausbildungsjahr': ausbildungsjahr,
      'von_datum': vonDatum.toIso8601String(),
      'bis_datum': bisDatum.toIso8601String(),
      'betriebliches': betriebliches,
      'schulisches': schulisches,
      'schulisches_pro_fach': schulischesProFach,
      'pause_minuten': pauseMinuten,
      'krankheitstage': krankheitstage,
      'urlaubstage': urlaubstage,
      'besonderheiten': besonderheiten,
      'notizen': notizen,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
