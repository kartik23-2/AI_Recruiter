import 'package:ai_recruiter/features/interview/domain/candidate_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CandidateProfile Model Tests', () {
    test('CandidateProfile.fromJson parses complete JSON correctly', () {
      final json = {
        'name': 'Jane Doe',
        'skills': ['Dart', 'Flutter', 'Python'],
        'projects': ['AI Recruiter App', 'Portfolio'],
        'education': ['B.S. Computer Science'],
        'experience': ['Senior Mobile Engineer at TechCorp'],
      };

      final profile = CandidateProfile.fromJson(json);

      expect(profile.name, equals('Jane Doe'));
      expect(profile.skills, equals(['Dart', 'Flutter', 'Python']));
      expect(profile.projects, equals(['AI Recruiter App', 'Portfolio']));
      expect(profile.education, equals(['B.S. Computer Science']));
      expect(profile.experience, equals(['Senior Mobile Engineer at TechCorp']));
    });

    test('CandidateProfile.fromJson handles missing or null fields gracefully', () {
      final json = <String, dynamic>{};

      final profile = CandidateProfile.fromJson(json);

      expect(profile.name, isEmpty);
      expect(profile.skills, isEmpty);
      expect(profile.projects, isEmpty);
      expect(profile.education, isEmpty);
      expect(profile.experience, isEmpty);
    });

    test('CandidateProfile.fromJson filters out non-string or empty elements', () {
      final json = {
        'name': 'Alex',
        'skills': ['Dart', 123, '', null, 'Flutter'],
      };

      final profile = CandidateProfile.fromJson(json);

      expect(profile.skills, equals(['Dart', '123', 'Flutter']));
    });

    test('CandidateProfile.toJson produces expected Map', () {
      const profile = CandidateProfile(
        name: 'John Smith',
        skills: ['Java', 'Kotlin'],
        projects: ['Android App'],
        education: ['B.Tech'],
        experience: ['Android Developer'],
      );

      final json = profile.toJson();

      expect(json['name'], equals('John Smith'));
      expect(json['skills'], equals(['Java', 'Kotlin']));
      expect(json['projects'], equals(['Android App']));
      expect(json['education'], equals(['B.Tech']));
      expect(json['experience'], equals(['Android Developer']));
    });
  });
}
