import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium App Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Voice Recruiter',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Empower your career with AI recruiting intelligence',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1, indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'CHOOSE YOUR PATHWAY',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Menu Cards list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMenuCard(
                      context: context,
                      title: 'Resume Interview',
                      description: 'Tailored assessment matching your specific CV & professional history.',
                      icon: Icons.description_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go('/resume-analysis'),
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Skill-Based Interview',
                      description: 'Test deep expertise in specific technology domains and platforms.',
                      icon: Icons.code_rounded,
                      color: AppColors.secondary,
                      onTap: () => context.go('/interview-setup'),
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Hybrid Interview',
                      description: 'Comprehensive evaluation covering both technical and background aspects.',
                      icon: Icons.psychology_rounded,
                      color: AppColors.accent,
                      onTap: () => context.go('/interview-setup'),
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Interview History',
                      description: 'Review transcripts, evaluation logs, scores, and past reports.',
                      icon: Icons.history_toggle_off_rounded,
                      color: AppColors.success,
                      onTap: () => context.go('/history'),
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Analytics',
                      description: 'View performance trends, scores, and improvement insights.',
                      icon: Icons.analytics_rounded,
                      color: AppColors.warning,
                      onTap: () => context.go('/analytics'),
                    ),
                    _buildMenuCard(
                      context: context,
                      title: 'Profile',
                      description: 'Manage personal credentials, default CV configurations, and audio settings.',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.textMuted,
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.12),
          highlightColor: color.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
