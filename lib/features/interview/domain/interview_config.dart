/// Interview configuration models and enums.

/// Interview mode determines the source of questions.
enum InterviewMode {
  resume,
  skill,
  hybrid;

  String get displayName {
    switch (this) {
      case InterviewMode.resume:
        return 'Resume-Based';
      case InterviewMode.skill:
        return 'Skill-Based';
      case InterviewMode.hybrid:
        return 'Hybrid';
    }
  }

  String get apiValue {
    switch (this) {
      case InterviewMode.resume:
        return 'resume';
      case InterviewMode.skill:
        return 'skill';
      case InterviewMode.hybrid:
        return 'hybrid';
    }
  }
}

/// Experience level of the candidate.
enum ExperienceLevel {
  fresher,
  zeroToOne,
  oneToThree,
  threePlus;

  String get displayName {
    switch (this) {
      case ExperienceLevel.fresher:
        return 'Fresher';
      case ExperienceLevel.zeroToOne:
        return '0-1 Years';
      case ExperienceLevel.oneToThree:
        return '1-3 Years';
      case ExperienceLevel.threePlus:
        return '3+ Years';
    }
  }

  String get apiValue {
    switch (this) {
      case ExperienceLevel.fresher:
        return 'fresher';
      case ExperienceLevel.zeroToOne:
        return '0-1 years';
      case ExperienceLevel.oneToThree:
        return '1-3 years';
      case ExperienceLevel.threePlus:
        return '3+ years';
    }
  }
}

/// Difficulty level of the interview.
enum Difficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

/// Available interview durations in minutes.
enum InterviewDuration {
  five(5),
  fifteen(15),
  thirty(30),
  fortyFive(45);

  const InterviewDuration(this.minutes);
  final int minutes;

  String get displayName => '$minutes min';
}

/// Full interview configuration chosen by the user.
class InterviewConfig {
  final InterviewMode mode;
  final String role;
  final ExperienceLevel experienceLevel;
  final Difficulty difficulty;
  final InterviewDuration duration;
  final List<String> skills;
  final String? resumeText;

  const InterviewConfig({
    required this.mode,
    required this.role,
    required this.experienceLevel,
    required this.difficulty,
    required this.duration,
    this.skills = const [],
    this.resumeText,
  });

  Map<String, dynamic> toApiJson() => {
    'mode': mode.apiValue,
    'role': role,
    'experience_level': experienceLevel.apiValue,
    'difficulty': difficulty.name,
    'duration_minutes': duration.minutes,
    'skills': skills,
    if (resumeText != null) 'resume_text': resumeText,
  };

  Map<String, dynamic> toFirestoreMap() => {
    'mode': mode.name,
    'role': role,
    'experienceLevel': experienceLevel.name,
    'difficulty': difficulty.name,
    'durationMinutes': duration.minutes,
    'skills': skills,
  };

  factory InterviewConfig.fromFirestore(Map<String, dynamic> data) {
    return InterviewConfig(
      mode: InterviewMode.values.firstWhere(
        (e) => e.name == data['mode'],
        orElse: () => InterviewMode.skill,
      ),
      role: data['role']?.toString() ?? 'Software Engineer',
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == data['experienceLevel'],
        orElse: () => ExperienceLevel.fresher,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      duration: InterviewDuration.values.firstWhere(
        (e) => e.minutes == (data['durationMinutes'] ?? 15),
        orElse: () => InterviewDuration.fifteen,
      ),
      skills: _parseStringList(data['skills']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}
