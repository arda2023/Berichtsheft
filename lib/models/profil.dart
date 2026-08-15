class Profil {
  final String name;
  final String adresse;
  final String ausbildungsberuf;
  final String fachrichtung;
  final String betriebName;
  final String betriebAdresse;
  final String ausbilder;
  final String ausbildungsbereich;
  final String wochenstunden;
  final String pause;
  final String arbeitszeiten;
  final String schultage;
  final String schulNotizen;
  final List<String> faecher;
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
    this.wochenstunden = '40 Std./Woche',
    this.pause = '30 min. pro Tag',
    this.arbeitszeiten = '8:00 - 16:30 Uhr',
    this.schultage = 'Montag und Donnerstag: 8:00 - 13:00 Uhr',
    this.schulNotizen = '',
    this.faecher = const [],
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
    String? wochenstunden,
    String? pause,
    String? arbeitszeiten,
    String? schultage,
    String? schulNotizen,
    List<String>? faecher,
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
      wochenstunden: wochenstunden ?? this.wochenstunden,
      pause: pause ?? this.pause,
      arbeitszeiten: arbeitszeiten ?? this.arbeitszeiten,
      schultage: schultage ?? this.schultage,
      schulNotizen: schulNotizen ?? this.schulNotizen,
      faecher: faecher ?? this.faecher,
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
      wochenstunden: json['wochenstunden'] as String? ?? '40 Std./Woche',
      pause: json['pause'] as String? ?? '30 min. pro Tag',
      arbeitszeiten: json['arbeitszeiten'] as String? ?? '8:00 - 16:30 Uhr',
      schultage: json['schultage'] as String? ?? 'Montag und Donnerstag: 8:00 - 13:00 Uhr',
      schulNotizen: json['schul_notizen'] as String? ?? '',
      faecher: List<String>.from(json['faecher'] ?? []),
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
      'wochenstunden': wochenstunden,
      'pause': pause,
      'arbeitszeiten': arbeitszeiten,
      'schultage': schultage,
      'schul_notizen': schulNotizen,
      'faecher': faecher,
      'ausbildungsbeginn': ausbildungsbeginn?.toIso8601String(),
      'ausbildungsende': ausbildungsende?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
