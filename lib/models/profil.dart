class Profil {
  final String name;
  final String adresse;
  final String ausbildungsberuf;
  final String fachrichtung;
  final String betriebName;
  final String betriebAdresse;
  final String ausbilder;
  final String ausbildungsbereich;
  final DateTime? ausbildungsbeginn;
  final DateTime? ausbildungsende;
  final DateTime? updatedAt;

  const Profil({
    this.name = '',
    this.adresse = '',
    this.ausbildungsberuf = '',
    this.fachrichtung = '',
    this.betriebName = '',
    this.betriebAdresse = '',
    this.ausbilder = '',
    this.ausbildungsbereich = '',
    this.ausbildungsbeginn,
    this.ausbildungsende,
    this.updatedAt,
  });

  Profil copyWith({
    String? name,
    String? adresse,
    String? ausbildungsberuf,
    String? fachrichtung,
    String? betriebName,
    String? betriebAdresse,
    String? ausbilder,
    String? ausbildungsbereich,
    DateTime? ausbildungsbeginn,
    DateTime? ausbildungsende,
    DateTime? updatedAt,
  }) {
    return Profil(
      name: name ?? this.name,
      adresse: adresse ?? this.adresse,
      ausbildungsberuf: ausbildungsberuf ?? this.ausbildungsberuf,
      fachrichtung: fachrichtung ?? this.fachrichtung,
      betriebName: betriebName ?? this.betriebName,
      betriebAdresse: betriebAdresse ?? this.betriebAdresse,
      ausbilder: ausbilder ?? this.ausbilder,
      ausbildungsbereich: ausbildungsbereich ?? this.ausbildungsbereich,
      ausbildungsbeginn: ausbildungsbeginn ?? this.ausbildungsbeginn,
      ausbildungsende: ausbildungsende ?? this.ausbildungsende,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profil.fromJson(Map<String, dynamic> json) {
    return Profil(
      name: json['name'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      ausbildungsberuf: json['ausbildungsberuf'] as String? ?? '',
      fachrichtung: json['fachrichtung'] as String? ?? '',
      betriebName: json['betrieb_name'] as String? ?? '',
      betriebAdresse: json['betrieb_adresse'] as String? ?? '',
      ausbilder: json['ausbilder'] as String? ?? '',
      ausbildungsbereich: json['ausbildungsbereich'] as String? ?? '',
      ausbildungsbeginn: json['ausbildungsbeginn'] != null
          ? DateTime.parse(json['ausbildungsbeginn'] as String)
          : null,
      ausbildungsende: json['ausbildungsende'] != null
          ? DateTime.parse(json['ausbildungsende'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'adresse': adresse,
      'ausbildungsberuf': ausbildungsberuf,
      'fachrichtung': fachrichtung,
      'betrieb_name': betriebName,
      'betrieb_adresse': betriebAdresse,
      'ausbilder': ausbilder,
      'ausbildungsbereich': ausbildungsbereich,
      'ausbildungsbeginn': ausbildungsbeginn?.toIso8601String(),
      'ausbildungsende': ausbildungsende?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
