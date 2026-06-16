/// Per-answer evaluation returned by the backend.
class AnswerEvaluation {
  final int technicalAccuracy;
  final int communication;
  final int confidence;
  final int problemSolving;
  final int overall;
  final String feedback;
  final String? followUpQuestion;

  const AnswerEvaluation({
    required this.technicalAccuracy,
    required this.communication,
    required this.confidence,
    required this.problemSolving,
    required this.overall,
    this.feedback = '',
    this.followUpQuestion,
  });

  factory AnswerEvaluation.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluation(
      technicalAccuracy: _parseInt(json['technical_accuracy']),
      communication: _parseInt(json['communication']),
      confidence: _parseInt(json['confidence']),
      problemSolving: _parseInt(json['problem_solving']),
      overall: _parseInt(json['overall']),
      feedback: json['feedback']?.toString() ?? '',
      followUpQuestion: json['follow_up_question']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'technical_accuracy': technicalAccuracy,
    'communication': communication,
    'confidence': confidence,
    'problem_solving': problemSolving,
    'overall': overall,
    'feedback': feedback,
    'follow_up_question': followUpQuestion,
  };

  Map<String, dynamic> toFirestoreMap() => toJson();

  factory AnswerEvaluation.fromFirestore(Map<String, dynamic> data) {
    return AnswerEvaluation.fromJson(data);
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    if (value is String) return (int.tryParse(value) ?? 0).clamp(0, 100);
    return 0;
  }

  /// Empty evaluation for unanswered questions.
  static const AnswerEvaluation empty = AnswerEvaluation(
    technicalAccuracy: 0,
    communication: 0,
    confidence: 0,
    problemSolving: 0,
    overall: 0,
    feedback: 'No answer provided.',
  );
}
