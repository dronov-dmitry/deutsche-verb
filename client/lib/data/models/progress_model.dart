class ProgressModel {
  const ProgressModel({
    required this.verbId,
    required this.status,
    required this.repetitions,
    required this.lastReviewed,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      verbId: json['verb_id'] as int,
      status: json['status'] as String,
      repetitions: json['repetitions'] as int? ?? 0,
      lastReviewed: json['last_reviewed'] as String,
    );
  }

  final int verbId;
  final String status;
  final int repetitions;
  final String lastReviewed;

  Map<String, dynamic> toJson() {
    return {
      'verb_id': verbId,
      'status': status,
      'repetitions': repetitions,
      'last_reviewed': lastReviewed,
    };
  }
}
