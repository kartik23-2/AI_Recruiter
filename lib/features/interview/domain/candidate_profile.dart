/// Structured profile extracted from a resume PDF.
class CandidateProfile {
  final String name;
  final List<String> skills;
  final List<String> projects;
  final List<String> education;
  final List<String> experience;

  const CandidateProfile({
    required this.name,
    required this.skills,
    required this.projects,
    required this.education,
    required this.experience,
  });

  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    return CandidateProfile(
      name: json['name'] as String? ?? '',
      skills: _parseStringList(json['skills']),
      projects: _parseStringList(json['projects']),
      education: _parseStringList(json['education']),
      experience: _parseStringList(json['experience']),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .where((e) => e != null)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty && s != 'null')
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'skills': skills,
        'projects': projects,
        'education': education,
        'experience': experience,
      };
}
