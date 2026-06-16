import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/interview_result.dart';
import '../services/interview_engine.dart';

class InterviewReportScreen extends StatelessWidget {
  const InterviewReportScreen({super.key, this.engine, this.result});

  /// Live engine (coming directly from an interview).
  final InterviewEngine? engine;

  /// Saved result (coming from history).
  final InterviewResult? result;

  InterviewReport? get _report => engine?.report ?? result?.report;
  List<InterviewQA> get _qaEntries => engine?.qaEntries ?? result?.qaEntries ?? [];
  String get _role =>
      engine?.config.role ?? result?.config.role ?? 'Interview';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _report;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: report == null
                    ? _buildNoReport(theme)
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildOverallScoreCard(theme, report),
                            const SizedBox(height: 16),
                            _buildScoreBreakdown(theme),
                            const SizedBox(height: 16),
                            _buildAnalysisCard(
                              theme,
                              title: 'Strengths',
                              icon: Icons.trending_up_rounded,
                              color: AppColors.success,
                              items: report.strengths,
                            ),
                            const SizedBox(height: 12),
                            _buildAnalysisCard(
                              theme,
                              title: 'Weaknesses',
                              icon: Icons.trending_down_rounded,
                              color: AppColors.error,
                              items: report.weaknesses,
                            ),
                            const SizedBox(height: 12),
                            _buildTextCard(
                              theme,
                              title: 'Communication Analysis',
                              icon: Icons.chat_rounded,
                              color: AppColors.accent,
                              text: report.communicationAnalysis,
                            ),
                            const SizedBox(height: 12),
                            _buildTextCard(
                              theme,
                              title: 'Technical Analysis',
                              icon: Icons.code_rounded,
                              color: AppColors.primary,
                              text: report.technicalAnalysis,
                            ),
                            const SizedBox(height: 12),
                            _buildAnalysisCard(
                              theme,
                              title: 'Areas To Improve',
                              icon: Icons.gps_fixed_rounded,
                              color: AppColors.warning,
                              items: report.areasToImprove,
                            ),
                            const SizedBox(height: 12),
                            _buildAnalysisCard(
                              theme,
                              title: 'Recommended Learning Topics',
                              icon: Icons.school_rounded,
                              color: AppColors.secondary,
                              items: report.recommendedTopics,
                            ),
                            const SizedBox(height: 12),
                            _buildAnalysisCard(
                              theme,
                              title: 'Recommended Interview Questions',
                              icon: Icons.quiz_rounded,
                              color: AppColors.accent,
                              items: report.recommendedQuestions,
                            ),
                            const SizedBox(height: 24),
                            _buildQADetailsCard(theme),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => context.go('/home'),
                                icon: const Icon(Icons.home_rounded),
                                label: const Text('Back to Home'),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
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
            onPressed: () => context.go('/home'),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Interview Report',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNoReport(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assessment_outlined,
              color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'No report available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(ThemeData theme, InterviewReport report) {
    final score = report.overallScore;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            _role,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            score >= 80
                ? 'Excellent Performance! 🌟'
                : score >= 60
                    ? 'Good Performance 👍'
                    : score >= 40
                        ? 'Needs Improvement 📝'
                        : 'Keep Practicing 💪',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_qaEntries.length} questions answered',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(ThemeData theme) {
    if (_qaEntries.isEmpty) return const SizedBox.shrink();

    // Average across all evaluations
    final evaluated = _qaEntries.where((e) => e.evaluation != null).toList();
    if (evaluated.isEmpty) return const SizedBox.shrink();

    int avgTech = 0, avgComm = 0, avgConf = 0, avgPS = 0;
    for (final qa in evaluated) {
      avgTech += qa.evaluation!.technicalAccuracy;
      avgComm += qa.evaluation!.communication;
      avgConf += qa.evaluation!.confidence;
      avgPS += qa.evaluation!.problemSolving;
    }
    final n = evaluated.length;
    avgTech = (avgTech / n).round();
    avgComm = (avgComm / n).round();
    avgConf = (avgConf / n).round();
    avgPS = (avgPS / n).round();

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
            'Score Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(theme, 'Technical Accuracy', avgTech, AppColors.primary),
          const SizedBox(height: 12),
          _buildScoreBar(theme, 'Communication', avgComm, AppColors.accent),
          const SizedBox(height: 12),
          _buildScoreBar(theme, 'Confidence', avgConf, AppColors.success),
          const SizedBox(height: 12),
          _buildScoreBar(theme, 'Problem Solving', avgPS, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildScoreBar(ThemeData theme, String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$score/100',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No data available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required String text,
  }) {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text.isEmpty ? 'No data available.' : text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: text.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQADetailsCard(ThemeData theme) {
    if (_qaEntries.isEmpty) return const SizedBox.shrink();

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
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Question Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_qaEntries.length, (i) {
            final qa = _qaEntries[i];
            final eval = qa.evaluation;
            final scoreColor = (eval?.overall ?? 0) >= 80
                ? AppColors.success
                : (eval?.overall ?? 0) >= 60
                    ? AppColors.warning
                    : AppColors.error;

            return Container(
              margin: EdgeInsets.only(bottom: i < _qaEntries.length - 1 ? 16 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q${i + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          qa.question.type.displayName,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (eval != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${eval.overall}/100',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    qa.question.question,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A: ${qa.answer}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (eval != null && eval.feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 ${eval.feedback}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.accent,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
