import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/interview_config.dart';
import '../services/interview_engine.dart';

class VoiceInterviewScreen extends StatefulWidget {
  const VoiceInterviewScreen({super.key, this.config});

  final InterviewConfig? config;

  @override
  State<VoiceInterviewScreen> createState() => _VoiceInterviewScreenState();
}

class _VoiceInterviewScreenState extends State<VoiceInterviewScreen> {
  late InterviewEngine _engine;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final config = widget.config ??
        const InterviewConfig(
          mode: InterviewMode.skill,
          role: 'Software Engineer',
          experienceLevel: ExperienceLevel.fresher,
          difficulty: Difficulty.medium,
          duration: InterviewDuration.fifteen,
          skills: ['Flutter', 'Dart'],
        );
    _engine = InterviewEngine(config: config);
    _engine.addListener(_onEngineUpdate);
    _engine.startInterview();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTimestamp(DateTime ts) {
    return TimeOfDay.fromDateTime(ts).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recruiterCount = _engine.messages
        .where((m) => m.speaker == MessageSpeaker.recruiter)
        .length;
    final candidateCount = _engine.messages
        .where((m) => m.speaker == MessageSpeaker.candidate)
        .length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProgressCard(theme),
                      const SizedBox(height: 16),
                      _buildStatusCard(theme),
                      const SizedBox(height: 16),
                      _buildConversationCard(theme, recruiterCount, candidateCount),
                      const SizedBox(height: 16),
                      _buildControlPanel(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('End Interview?',
                      style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text(
                    'Are you sure you want to end this interview? Your progress will be saved.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Continue'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _engine.endInterviewEarly();
                      },
                      child: const Text('End Interview'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Voice Interview',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (_engine.isCompleted)
            IconButton(
              onPressed: () => context.go('/interview-report',
                  extra: _engine),
              icon: const Icon(Icons.assessment_rounded,
                  color: AppColors.accent, size: 24),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final phase = _engine.phase;
    final isGenerating = phase == EnginePhase.generatingQuestions;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _engine.config.mode == InterviewMode.resume
                    ? Icons.description_rounded
                    : _engine.config.mode == InterviewMode.skill
                        ? Icons.code_rounded
                        : Icons.psychology_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_engine.config.mode.displayName} • ${_engine.config.role}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isGenerating
                      ? 'Loading...'
                      : 'Q ${_engine.currentIndex + 1}/${_engine.totalQuestions}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isGenerating ? null : _engine.progress,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                  '${_engine.config.difficulty.displayName}',
                  _engine.config.difficulty == Difficulty.easy
                      ? AppColors.success
                      : _engine.config.difficulty == Difficulty.medium
                          ? AppColors.warning
                          : AppColors.error),
              const SizedBox(width: 8),
              _buildInfoChip(
                  _engine.config.experienceLevel.displayName, AppColors.secondary),
              const SizedBox(width: 8),
              _buildInfoChip(
                  '${_engine.config.duration.minutes} min', AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final phase = _engine.phase;
    final statusColor = switch (phase) {
      EnginePhase.recruiterSpeaking => AppColors.warning,
      EnginePhase.listening => AppColors.success,
      EnginePhase.completed => AppColors.accent,
      EnginePhase.error => AppColors.error,
      EnginePhase.evaluatingAnswer ||
      EnginePhase.generatingReport =>
        AppColors.secondary,
      _ => AppColors.primary,
    };

    final statusLabel = switch (phase) {
      EnginePhase.idle => 'Ready',
      EnginePhase.generatingQuestions => '⏳ Generating Questions...',
      EnginePhase.recruiterSpeaking => '🔊 Recruiter Speaking...',
      EnginePhase.waitingForAnswer => '🎤 Waiting For Candidate...',
      EnginePhase.listening => '🎙 Listening...',
      EnginePhase.answerCaptured => '✅ Answer Captured',
      EnginePhase.evaluatingAnswer => '🧠 Evaluating Answer...',
      EnginePhase.generatingReport => '📊 Generating Report...',
      EnginePhase.completed => '🏁 Interview Complete',
      EnginePhase.error => '❌ Error',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_engine.evaluations.containsKey(_engine.currentIndex - 1))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last: ${_engine.evaluations[_engine.currentIndex - 1]!.overall}/100',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _engine.statusMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (_engine.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                _engine.errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationCard(
      ThemeData theme, int recruiterCount, int candidateCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                'Live Transcript',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$recruiterCount Q · $candidateCount A',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: _engine.messages.isEmpty
                ? _buildEmptyConversation(theme)
                : ListView.separated(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _engine.messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildBubble(context, _engine.messages[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversation(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic_none_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            _engine.phase == EnginePhase.generatingQuestions
                ? 'Generating your interview questions...'
                : 'The conversation will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (_engine.phase == EnginePhase.generatingQuestions) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, TranscriptMessage message) {
    final isRecruiter = message.speaker == MessageSpeaker.recruiter;
    final theme = Theme.of(context);
    final isActive = message.isDraft && _engine.phase == EnginePhase.listening;

    final bubbleColor = isRecruiter
        ? AppColors.primary.withValues(alpha: 0.12)
        : isActive
            ? AppColors.accent.withValues(alpha: 0.18)
            : AppColors.surfaceLight.withValues(alpha: 0.62);

    final borderColor = isRecruiter
        ? AppColors.primary.withValues(alpha: 0.35)
        : isActive
            ? AppColors.accent.withValues(alpha: 0.45)
            : AppColors.border;

    final displayText = message.text.trim().isEmpty && message.isDraft
        ? 'Listening...'
        : message.text.trim().isEmpty
            ? 'No speech detected.'
            : message.text.trim();

    // Check if there's an evaluation for this candidate answer
    final eval = !isRecruiter
        ? _engine.evaluations[message.questionIndex]
        : null;

    return Align(
      alignment: isRecruiter ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isRecruiter
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeakerChip(
                  isRecruiter ? 'Recruiter' : 'Candidate',
                  isRecruiter ? AppColors.primary : AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                displayText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                  fontWeight:
                      message.isDraft ? FontWeight.w500 : FontWeight.w600,
                ),
              ),
            ),
            if (!isRecruiter && eval != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildScorePill('Score', eval.overall, AppColors.primary),
                  const SizedBox(width: 6),
                  _buildScorePill('Tech', eval.technicalAccuracy, AppColors.accent),
                  const SizedBox(width: 6),
                  _buildScorePill('Comm', eval.communication, AppColors.success),
                ],
              ),
            ],
            if (!isRecruiter && message.isDraft) ...[
              const SizedBox(height: 4),
              Text(
                'Live transcript',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScorePill(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $score',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSpeakerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildControlPanel(ThemeData theme) {
    final phase = _engine.phase;
    final canListen = phase == EnginePhase.waitingForAnswer;
    final canSkip = phase == EnginePhase.waitingForAnswer ||
        phase == EnginePhase.listening ||
        phase == EnginePhase.answerCaptured;
    final isComplete = _engine.isCompleted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controls',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (isComplete) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.go('/interview-report', extra: _engine),
                icon: const Icon(Icons.assessment_rounded),
                label: const Text('View Report'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else if (phase == EnginePhase.error) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _engine.startInterview();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: canListen ? () => _engine.startListening() : null,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Start Answer'),
                ),
                OutlinedButton.icon(
                  onPressed: canSkip ? () => _engine.skipQuestion() : null,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Skip'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _engine.endInterviewEarly(),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('End'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'The microphone auto-starts after each question. '
            'If you stop speaking for 5 seconds, your answer is captured automatically.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
