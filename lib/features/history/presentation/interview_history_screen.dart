import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/auth_service.dart';
import '../../interview/data/interview_repository.dart';
import '../../interview/domain/interview_config.dart';
import '../../interview/domain/interview_result.dart';

class InterviewHistoryScreen extends StatefulWidget {
  const InterviewHistoryScreen({super.key});

  @override
  State<InterviewHistoryScreen> createState() => _InterviewHistoryScreenState();
}

class _InterviewHistoryScreenState extends State<InterviewHistoryScreen> {
  bool _isLoading = true;
  List<InterviewResult> _interviews = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final interviews =
          await InterviewRepository.instance.fetchAllInterviews(uid);
      if (mounted) {
        setState(() {
          _interviews = interviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _interviews.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _interviews.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildInterviewCard(
                                    theme, _interviews[index]);
                              },
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
              'Interview History',
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.history_rounded,
                  color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'No Interviews Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your interview history will appear here after you complete your first interview.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/interview-setup'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Interview'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewCard(ThemeData theme, InterviewResult interview) {
    final score = interview.report?.overallScore ?? interview.averageScore;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.error;

    final modeColor = interview.config.mode == InterviewMode.resume
        ? AppColors.primary
        : interview.config.mode == InterviewMode.skill
            ? AppColors.secondary
            : AppColors.accent;

    return GestureDetector(
      onTap: () => context.go('/interview-report', extra: interview),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interview.config.role,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interview.config.mode.displayName,
                          style: TextStyle(
                            color: modeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          interview.config.difficulty.displayName,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${interview.qaEntries.length} Q',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(interview.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
