/// Orchestrates the full interview flow: questions → TTS → STT → evaluation → report.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/data/auth_service.dart';
import '../data/interview_api_service.dart';
import '../data/interview_repository.dart';
import '../domain/answer_evaluation.dart';
import '../domain/interview_config.dart';
import '../domain/interview_question.dart';
import '../domain/interview_result.dart';
import 'speech_service.dart';
import 'tts_service.dart';

// ── State Machine ───────────────────────────────────────────────────────────

enum EnginePhase {
  idle,
  generatingQuestions,
  recruiterSpeaking,
  waitingForAnswer,
  listening,
  answerCaptured,
  evaluatingAnswer,
  generatingReport,
  completed,
  error,
}

// ── Transcript Message ──────────────────────────────────────────────────────

enum MessageSpeaker { recruiter, candidate }

class TranscriptMessage {
  final MessageSpeaker speaker;
  final int questionIndex;
  final String text;
  final DateTime timestamp;
  final bool isDraft;

  const TranscriptMessage({
    required this.speaker,
    required this.questionIndex,
    required this.text,
    required this.timestamp,
    this.isDraft = false,
  });

  TranscriptMessage copyWith({String? text, bool? isDraft}) {
    return TranscriptMessage(
      speaker: speaker,
      questionIndex: questionIndex,
      text: text ?? this.text,
      timestamp: timestamp,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}

// ── Interview Engine ────────────────────────────────────────────────────────

class InterviewEngine extends ChangeNotifier {
  InterviewEngine({required this.config});

  final InterviewConfig config;
  final TtsService _tts = TtsService.instance;
  final SpeechService _stt = SpeechService.instance;
  final InterviewApiService _api = InterviewApiService.instance;
  final InterviewRepository _repo = InterviewRepository.instance;

  // State
  EnginePhase _phase = EnginePhase.idle;
  EnginePhase get phase => _phase;

  List<InterviewQuestion> _questions = [];
  List<InterviewQuestion> get questions => _questions;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  int get totalQuestions => _questions.length;
  double get progress =>
      totalQuestions == 0 ? 0 : (_currentIndex / totalQuestions);

  final List<TranscriptMessage> messages = [];
  final List<InterviewQA> qaEntries = [];
  final Map<int, AnswerEvaluation> evaluations = {};

  InterviewReport? _report;
  InterviewReport? get report => _report;

  String? _savedInterviewId;
  String? get savedInterviewId => _savedInterviewId;

  String _statusMessage = 'Preparing interview...';
  String get statusMessage => _statusMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  Timer? _silenceTimer;
  int? _activeDraftIndex;

  bool get isCompleted => _phase == EnginePhase.completed;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> startInterview() async {
    _setPhase(EnginePhase.generatingQuestions);
    _statusMessage = 'Generating interview questions...';
    _errorMessage = null;
    notifyListeners();

    try {
      _questions = await _api.generateQuestions(config);
    } on InterviewApiException catch (e) {
      _setError('Failed to generate questions: ${e.message}');
      return;
    } catch (e) {
      _setError('Failed to generate questions. Check your connection.');
      return;
    }

    if (_questions.isEmpty) {
      _setError('No questions were generated. Please adjust your settings.');
      return;
    }

    _currentIndex = 0;
    messages.clear();
    qaEntries.clear();
    evaluations.clear();
    _report = null;
    _savedInterviewId = null;

    // Setup TTS callbacks
    await _tts.initialize(
      onStart: () => _onTtsStart(),
      onComplete: () => _onTtsComplete(),
      onError: (msg) => _onTtsError(msg),
    );

    await _askCurrentQuestion();
  }

  Future<void> dispose() async {
    _silenceTimer?.cancel();
    await _tts.stop();
    await _stt.stopListening();
    super.dispose();
  }

  // ── Question Flow ─────────────────────────────────────────────────────────

  Future<void> _askCurrentQuestion() async {
    if (_currentIndex >= _questions.length) {
      await _finishInterview();
      return;
    }

    final q = _questions[_currentIndex];
    _liveTranscript = '';
    _activeDraftIndex = null;
    _errorMessage = null;

    // Add recruiter message
    messages.add(TranscriptMessage(
      speaker: MessageSpeaker.recruiter,
      questionIndex: _currentIndex,
      text: q.question,
      timestamp: DateTime.now(),
    ));

    _setPhase(EnginePhase.recruiterSpeaking);
    _statusMessage = '🔊 Recruiter Speaking...';
    notifyListeners();

    await _tts.speak(q.question);
  }

  void _onTtsStart() {
    _setPhase(EnginePhase.recruiterSpeaking);
    _statusMessage = '🔊 Recruiter Speaking...';
    notifyListeners();
  }

  void _onTtsComplete() {
    if (_phase == EnginePhase.completed) return;
    _setPhase(EnginePhase.waitingForAnswer);
    _statusMessage = '🎤 Waiting For Candidate...';
    notifyListeners();

    // Auto-start listening after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_phase == EnginePhase.waitingForAnswer) {
        startListening();
      }
    });
  }

  void _onTtsError(String msg) {
    // Treat TTS failure as non-fatal; still allow answering
    _setPhase(EnginePhase.waitingForAnswer);
    _statusMessage = '🎤 Waiting For Candidate...';
    _errorMessage = 'Voice playback issue: $msg';
    notifyListeners();
  }

  // ── Speech-to-Text ────────────────────────────────────────────────────────

  Future<void> startListening() async {
    if (_phase != EnginePhase.waitingForAnswer &&
        _phase != EnginePhase.answerCaptured) {
      return;
    }

    _silenceTimer?.cancel();
    _setPhase(EnginePhase.listening);
    _statusMessage = '🎙 Listening...';
    _errorMessage = null;
    _liveTranscript = '';
    _ensureDraftMessage();
    notifyListeners();

    final err = await _stt.startListening(
      onResult: _onSpeechResult,
      onError: _onSpeechError,
      onStatus: (status) {
        if (status == 'notListening' && _phase == EnginePhase.listening) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (_phase == EnginePhase.listening) {
              _finalizeAnswer(trigger: 'speech-status');
            }
          });
        }
      },
    );

    if (err != null) {
      _setPhase(EnginePhase.waitingForAnswer);
      _errorMessage = err;
      _statusMessage = err;
      notifyListeners();
      return;
    }

    _startSilenceTimer();
  }

  void _onSpeechResult(String transcript) {
    final normalized = transcript.trim();
    if (normalized.isEmpty) return;
    if (_liveTranscript.trim() == normalized) {
      _startSilenceTimer();
      return;
    }

    _liveTranscript = normalized;
    _statusMessage = '🎙 Listening...';
    _errorMessage = null;

    if (_activeDraftIndex != null && _activeDraftIndex! < messages.length) {
      messages[_activeDraftIndex!] = messages[_activeDraftIndex!].copyWith(
        text: normalized,
        isDraft: true,
      );
    }

    _startSilenceTimer();
    notifyListeners();
  }

  void _onSpeechError(String msg) {
    _errorMessage = msg;
    _finalizeAnswer(trigger: 'speech-error');
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (_phase == EnginePhase.listening) {
        _finalizeAnswer(trigger: 'silence-timeout');
      }
    });
  }

  Future<void> _finalizeAnswer({required String trigger}) async {
    _silenceTimer?.cancel();
    await _stt.stopListening();

    final text = _liveTranscript.trim();
    final finalText = text.isEmpty ? 'No speech detected.' : text;

    // Finalize the draft message
    if (_activeDraftIndex != null && _activeDraftIndex! < messages.length) {
      messages[_activeDraftIndex!] = messages[_activeDraftIndex!].copyWith(
        text: finalText,
        isDraft: false,
      );
    } else {
      messages.add(TranscriptMessage(
        speaker: MessageSpeaker.candidate,
        questionIndex: _currentIndex,
        text: finalText,
        timestamp: DateTime.now(),
      ));
    }

    _setPhase(EnginePhase.answerCaptured);
    _statusMessage = '✅ Answer Captured';
    notifyListeners();

    // Evaluate the answer
    await _evaluateCurrentAnswer(finalText);
  }

  void _ensureDraftMessage() {
    if (_activeDraftIndex != null) return;
    messages.add(TranscriptMessage(
      speaker: MessageSpeaker.candidate,
      questionIndex: _currentIndex,
      text: '',
      timestamp: DateTime.now(),
      isDraft: true,
    ));
    _activeDraftIndex = messages.length - 1;
  }

  // ── Answer Evaluation ─────────────────────────────────────────────────────

  Future<void> _evaluateCurrentAnswer(String answerText) async {
    _setPhase(EnginePhase.evaluatingAnswer);
    _statusMessage = 'Evaluating answer...';
    notifyListeners();

    final question = _questions[_currentIndex];
    AnswerEvaluation eval;

    try {
      eval = await _api.evaluateAnswer(
        question: question.question,
        questionType: question.type.name,
        answer: answerText,
        role: config.role,
        difficulty: config.difficulty.name,
      );
    } catch (e) {
      debugPrint('Evaluation error: $e');
      eval = AnswerEvaluation.empty;
    }

    evaluations[_currentIndex] = eval;

    // Store Q&A entry
    qaEntries.add(InterviewQA(
      question: question,
      answer: answerText,
      transcript: answerText,
      evaluation: eval,
    ));

    // Check if there's a follow-up question (1-deep only)
    if (eval.followUpQuestion != null &&
        eval.followUpQuestion!.trim().isNotEmpty &&
        !question.isFollowUp) {
      // Insert follow-up as next question
      final followUp = InterviewQuestion(
        question: eval.followUpQuestion!,
        type: QuestionType.followUp,
        source: 'follow-up to Q${_currentIndex + 1}',
        isFollowUp: true,
      );
      _questions.insert(_currentIndex + 1, followUp);
    }

    _statusMessage =
        '✅ Score: ${eval.overall}/100 — Moving to next question...';
    notifyListeners();

    // Brief pause then advance
    await Future<void>.delayed(const Duration(seconds: 2));
    _currentIndex++;
    _activeDraftIndex = null;
    await _askCurrentQuestion();
  }

  // ── Report Generation ─────────────────────────────────────────────────────

  Future<void> _finishInterview() async {
    _setPhase(EnginePhase.generatingReport);
    _statusMessage = 'Generating interview report...';
    notifyListeners();

    // Build questions payload for report API
    final questionsPayload = qaEntries.map((qa) {
      return {
        'question': qa.question.question,
        'question_type': qa.question.type.name,
        'answer': qa.answer,
        'scores': qa.evaluation?.toJson() ?? {},
      };
    }).toList();

    try {
      _report = await _api.generateReport(
        role: config.role,
        difficulty: config.difficulty.name,
        experienceLevel: config.experienceLevel.apiValue,
        questions: questionsPayload,
      );
    } catch (e) {
      debugPrint('Report generation error: $e');
      // Create a minimal report from the evaluations we have
      _report = _buildFallbackReport();
    }

    // Save to Firestore
    await _saveToFirestore();

    _setPhase(EnginePhase.completed);
    _statusMessage = 'Interview complete!';
    notifyListeners();
  }

  InterviewReport _buildFallbackReport() {
    final avgScore = qaEntries.isEmpty
        ? 0
        : qaEntries
            .where((e) => e.evaluation != null)
            .fold<int>(0, (acc, e) => acc + e.evaluation!.overall) ~/
            qaEntries.where((e) => e.evaluation != null).length;

    return InterviewReport(
      overallScore: avgScore,
      strengths: ['Interview completed successfully'],
      weaknesses: ['Report generation encountered an issue'],
      communicationAnalysis: 'Full analysis unavailable.',
      technicalAnalysis: 'Full analysis unavailable.',
      areasToImprove: ['Review detailed question scores for insights'],
      recommendedTopics: [],
      recommendedQuestions: [],
    );
  }

  Future<void> _saveToFirestore() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('InterviewEngine: cannot save — user not logged in');
      return;
    }

    try {
      final result = InterviewResult(
        config: config,
        qaEntries: qaEntries,
        report: _report,
        createdAt: DateTime.now(),
      );
      _savedInterviewId = await _repo.saveInterview(
        uid: uid,
        result: result,
      );
      debugPrint('InterviewEngine: saved interview $_savedInterviewId');
    } catch (e) {
      debugPrint('InterviewEngine: Firestore save failed: $e');
    }
  }

  // ── Manual Controls ───────────────────────────────────────────────────────

  /// Manually skip to the next question.
  Future<void> skipQuestion() async {
    if (_phase == EnginePhase.listening ||
        _phase == EnginePhase.waitingForAnswer ||
        _phase == EnginePhase.answerCaptured) {
      _silenceTimer?.cancel();
      await _stt.stopListening();
      await _tts.stop();

      // Record a skipped answer
      final question = _questions[_currentIndex];
      qaEntries.add(InterviewQA(
        question: question,
        answer: 'Skipped',
        transcript: '',
        evaluation: AnswerEvaluation.empty,
      ));

      _currentIndex++;
      _activeDraftIndex = null;
      _liveTranscript = '';
      await _askCurrentQuestion();
    }
  }

  /// Force stop the entire interview and generate report.
  Future<void> endInterviewEarly() async {
    _silenceTimer?.cancel();
    await _stt.stopListening();
    await _tts.stop();
    await _finishInterview();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setPhase(EnginePhase newPhase) {
    _phase = newPhase;
  }

  void _setError(String message) {
    _phase = EnginePhase.error;
    _statusMessage = message;
    _errorMessage = message;
    notifyListeners();
  }
}
