// HTTP client for the interview backend endpoints.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../domain/answer_evaluation.dart';
import '../domain/interview_config.dart';
import '../domain/interview_question.dart';
import '../domain/interview_result.dart';

class InterviewApiException implements Exception {
  final String message;
  InterviewApiException(this.message);

  @override
  String toString() => message;
}

/// Calls the 3 interview backend endpoints.
class InterviewApiService {
  InterviewApiService._();
  static final InterviewApiService instance = InterviewApiService._();

  static const _timeout = Duration(seconds: 90);

  /// Generate interview questions from config.
  Future<List<InterviewQuestion>> generateQuestions(
    InterviewConfig config,
  ) async {
    final uri = Uri.parse(ApiConfig.generateQuestionsUrl);
    final body = jsonEncode(config.toApiJson());

    debugPrint('InterviewAPI: POST $uri');
    debugPrint('InterviewAPI: body=$body');

    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);
    } on SocketException {
      throw InterviewApiException(
        'Cannot reach the backend at ${ApiConfig.baseUrl}. '
        'Make sure the server is running.',
      );
    } catch (e) {
      throw InterviewApiException('Network error: $e');
    }

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => InterviewQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw InterviewApiException(_extractError(response));
  }

  /// Evaluate a single answer.
  Future<AnswerEvaluation> evaluateAnswer({
    required String question,
    required String questionType,
    required String answer,
    required String role,
    required String difficulty,
  }) async {
    final uri = Uri.parse(ApiConfig.evaluateAnswerUrl);
    final body = jsonEncode({
      'question': question,
      'question_type': questionType,
      'answer': answer,
      'role': role,
      'difficulty': difficulty,
    });

    debugPrint('InterviewAPI: POST $uri (evaluate)');

    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_timeout);
    } on SocketException {
      throw InterviewApiException(
        'Cannot reach the backend. Make sure the server is running.',
      );
    } catch (e) {
      throw InterviewApiException('Network error: $e');
    }

    if (response.statusCode == 200) {
      return AnswerEvaluation.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw InterviewApiException(_extractError(response));
  }

  /// Generate a final interview report.
  Future<InterviewReport> generateReport({
    required String role,
    required String difficulty,
    required String experienceLevel,
    required List<Map<String, dynamic>> questions,
  }) async {
    final uri = Uri.parse(ApiConfig.generateReportUrl);
    final body = jsonEncode({
      'role': role,
      'difficulty': difficulty,
      'experience_level': experienceLevel,
      'questions': questions,
    });

    debugPrint('InterviewAPI: POST $uri (report)');

    http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 120));
    } on SocketException {
      throw InterviewApiException(
        'Cannot reach the backend. Make sure the server is running.',
      );
    } catch (e) {
      throw InterviewApiException('Network error: $e');
    }

    if (response.statusCode == 200) {
      return InterviewReport.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw InterviewApiException(_extractError(response));
  }

  String _extractError(http.Response response) {
    String message = 'Request failed (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['detail'] != null) {
        message = body['detail'].toString();
      }
    } catch (_) {}
    return message;
  }
}
