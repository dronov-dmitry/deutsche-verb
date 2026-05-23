class VerbModel {
  const VerbModel({
    required this.id,
    required this.infinitive,
    required this.translation,
    this.translationUk,
    required this.type,
    required this.pastParticiple,
    required this.preterite,
    required this.auxiliaryVerb,
    required this.level,
    required this.exampleSentence,
    required this.exampleTranslation,
    this.exampleTranslationUk = '',
    this.progressStatus = 'learning',
    this.repetitions = 0,
    this.lastReviewed,
    this.description = '',
    this.descriptionUk = '',
  });

  factory VerbModel.fromJson(Map<String, dynamic> json) {
    return VerbModel(
      id: json['id'] as int,
      infinitive: json['infinitive'] as String,
      translation: json['translation'] as String,
      translationUk: json['translation_uk'] as String?,
      type: json['type'] as String,
      pastParticiple: json['past_participle'] as String,
      preterite: json['preterite'] as String,
      auxiliaryVerb: json['auxiliary_verb'] as String,
      level: json['level'] as String,
      exampleSentence: json['example_sentence'] as String,
      exampleTranslation: json['example_translation'] as String,
      exampleTranslationUk: json['example_translation_uk'] as String? ?? '',
      progressStatus: json['progress_status'] as String? ?? 'learning',
      repetitions: json['repetitions'] as int? ?? 0,
      lastReviewed: json['last_reviewed'] as String?,
      description: json['description'] as String? ?? '',
      descriptionUk: json['description_uk'] as String? ?? '',
    );
  }

  factory VerbModel.fromDb(Map<String, dynamic> row) {
    return VerbModel(
      id: row['id'] as int,
      infinitive: row['infinitive'] as String,
      translation: row['translation'] as String,
      translationUk: row['translation_uk'] as String?,
      type: row['type'] as String,
      pastParticiple: row['past_participle'] as String,
      preterite: row['preterite'] as String,
      auxiliaryVerb: row['auxiliary_verb'] as String,
      level: row['level'] as String,
      exampleSentence: row['example_sentence'] as String,
      exampleTranslation: row['example_translation'] as String,
      exampleTranslationUk: row['example_translation_uk'] as String? ?? '',
      description: row['description'] as String? ?? '',
      descriptionUk: row['description_uk'] as String? ?? '',
    );
  }

  final int id;
  final String infinitive;
  final String translation;
  final String? translationUk;
  final String type;
  final String pastParticiple;
  final String preterite;
  final String auxiliaryVerb;
  final String level;
  final String exampleSentence;
  final String exampleTranslation;
  final String exampleTranslationUk;
  final String progressStatus;
  final int repetitions;
  final String? lastReviewed;
  final String description;
  final String descriptionUk;

  String translationFor(String locale) {
    if (locale == 'uk' && translationUk != null && translationUk!.isNotEmpty) {
      return translationUk!;
    }
    return translation;
  }

  String exampleTranslationFor(String locale) {
    if (locale == 'uk' && exampleTranslationUk.isNotEmpty) {
      return exampleTranslationUk;
    }
    return exampleTranslation;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'infinitive': infinitive,
      'translation': translation,
      'translation_uk': translationUk,
      'type': type,
      'past_participle': pastParticiple,
      'preterite': preterite,
      'auxiliary_verb': auxiliaryVerb,
      'level': level,
      'example_sentence': exampleSentence,
      'example_translation': exampleTranslation,
      'example_translation_uk': exampleTranslationUk,
      'progress_status': progressStatus,
      'repetitions': repetitions,
      'last_reviewed': lastReviewed,
      'description': description,
      'description_uk': descriptionUk,
    };
  }

  VerbModel copyWith({
    String? progressStatus,
    int? repetitions,
    String? lastReviewed,
  }) {
    return VerbModel(
      id: id,
      infinitive: infinitive,
      translation: translation,
      translationUk: translationUk,
      type: type,
      pastParticiple: pastParticiple,
      preterite: preterite,
      auxiliaryVerb: auxiliaryVerb,
      level: level,
      exampleSentence: exampleSentence,
      exampleTranslation: exampleTranslation,
      exampleTranslationUk: exampleTranslationUk,
      progressStatus: progressStatus ?? this.progressStatus,
      repetitions: repetitions ?? this.repetitions,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      description: description,
      descriptionUk: descriptionUk,
    );
  }
}
