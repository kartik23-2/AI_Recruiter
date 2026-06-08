import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../domain/candidate_profile.dart';

class ResumeAnalysisException implements Exception {
  final String message;
  ResumeAnalysisException(this.message);

  @override
  String toString() => message;
}

/// Sends resume PDFs to the backend and parses the structured response.
class ResumeService {
  ResumeService._();
  static final ResumeService instance = ResumeService._();

  Future<CandidateProfile> analyzeResume(File pdfFile) async {
    final uri = Uri.parse(ApiConfig.analyzeResumeUrl);
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
          filename: pdfFile.path.split(Platform.pathSeparator).last,
        ),
      );

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
    } on SocketException {
      throw ResumeAnalysisException(
        'Cannot reach the backend at ${ApiConfig.baseUrl}. '
        'Make sure the server is running.',
      );
    } catch (_) {
      throw ResumeAnalysisException(
        'Network error while uploading resume. Please try again.',
      );
    }

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CandidateProfile.fromJson(json);
      } catch (_) {
        throw ResumeAnalysisException(
          'Invalid response from server. Please try again.',
        );
      }
    }

    String message = 'Resume analysis failed (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['detail'] != null) {
        message = body['detail'].toString();
      }
    } catch (_) {}

    throw ResumeAnalysisException(message);
  }
}
