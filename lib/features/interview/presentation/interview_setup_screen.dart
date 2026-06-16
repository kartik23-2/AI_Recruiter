import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../auth/data/auth_service.dart';
import '../data/resume_repository.dart';
import '../data/resume_service.dart';
import '../domain/interview_config.dart';

class InterviewSetupScreen extends StatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  // Config state
  InterviewMode _mode = InterviewMode.skill;
  final TextEditingController _roleController = TextEditingController(
    text: 'Software Engineer',
  );
  ExperienceLevel _experience = ExperienceLevel.fresher;
  Difficulty _difficulty = Difficulty.medium;
  InterviewDuration _duration = InterviewDuration.fifteen;

  // Skills input
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];

  // Resume
  File? _resumeFile;
  String? _resumeFileName;
  String? _resumeText;
  bool _isUploadingResume = false;
  bool _isLoadingStoredResume = true;
  bool _hasStoredResume = false;

  @override
  void initState() {
    super.initState();
    _loadStoredResumeSkills();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredResumeSkills() async {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingStoredResume = false);
      return;
    }

    try {
      final profile = await ResumeRepository.instance.readProfile(uid);
      if (mounted && profile != null) {
        setState(() {
          _hasStoredResume = true;
          // Pre-fill skills from resume if user hasn't added any
          if (_skills.isEmpty && profile.skills.isNotEmpty) {
            _skills.addAll(profile.skills.take(10));
          }
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingStoredResume = false);
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _resumeFile = File(file.path!);
      _resumeFileName = file.name;
      _isUploadingResume = true;
    });

    try {
      final profile = await ResumeService.instance.analyzeResume(_resumeFile!);
      if (mounted) {
        setState(() {
          _resumeText = [
            'Name: ${profile.name}',
            'Skills: ${profile.skills.join(", ")}',
            'Projects: ${profile.projects.join(", ")}',
            'Experience: ${profile.experience.join(", ")}',
            'Education: ${profile.education.join(", ")}',
          ].join('\n');
          _isUploadingResume = false;

          // Auto-fill skills from resume analysis
          if (_skills.isEmpty) {
            _skills.addAll(profile.skills.take(10));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingResume = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume analysis failed: $e')),
        );
      }
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _startInterview() {
    final role = _roleController.text.trim();
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target role.')),
      );
      return;
    }

    if (_mode == InterviewMode.skill && _skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill.')),
      );
      return;
    }

    if (_mode == InterviewMode.resume && _resumeText == null && !_hasStoredResume) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a resume first.')),
      );
      return;
    }

    final config = InterviewConfig(
      mode: _mode,
      role: role,
      experienceLevel: _experience,
      difficulty: _difficulty,
      duration: _duration,
      skills: _skills,
      resumeText: _resumeText,
    );

    context.go('/voice-interview', extra: config);
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(theme, 'INTERVIEW MODE'),
                      const SizedBox(height: 12),
                      _buildModeSelector(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'TARGET ROLE'),
                      const SizedBox(height: 12),
                      _buildRoleInput(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'EXPERIENCE LEVEL'),
                      const SizedBox(height: 12),
                      _buildExperienceSelector(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'DIFFICULTY'),
                      const SizedBox(height: 12),
                      _buildDifficultySelector(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'DURATION'),
                      const SizedBox(height: 12),
                      _buildDurationSelector(theme),
                      const SizedBox(height: 24),
                      if (_mode != InterviewMode.skill) ...[
                        _buildSectionTitle(theme, 'RESUME (OPTIONAL)'),
                        const SizedBox(height: 12),
                        _buildResumeSection(theme),
                        const SizedBox(height: 24),
                      ],
                      if (_mode != InterviewMode.resume) ...[
                        _buildSectionTitle(theme, 'SKILLS'),
                        const SizedBox(height: 12),
                        _buildSkillsInput(theme),
                        const SizedBox(height: 24),
                      ],
                      GradientButton(
                        onPressed: _isUploadingResume ? null : _startInterview,
                        isLoading: false,
                        label: '🎙 Start Interview',
                      ),
                      const SizedBox(height: 16),
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
              'Interview Setup',
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Row(
      children: InterviewMode.values.map((mode) {
        final isSelected = _mode == mode;
        final color = mode == InterviewMode.resume
            ? AppColors.primary
            : mode == InterviewMode.skill
                ? AppColors.secondary
                : AppColors.accent;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode != InterviewMode.hybrid ? 8 : 0,
              left: mode != InterviewMode.resume ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _mode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mode == InterviewMode.resume
                          ? Icons.description_rounded
                          : mode == InterviewMode.skill
                              ? Icons.code_rounded
                              : Icons.psychology_rounded,
                      color: isSelected ? color : AppColors.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleInput(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _roleController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'e.g., Flutter Developer, ML Engineer',
          hintStyle: TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(Icons.work_outline_rounded, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildExperienceSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExperienceLevel.values.map((level) {
        final isSelected = _experience == level;
        return ChoiceChip(
          label: Text(level.displayName),
          selected: isSelected,
          onSelected: (_) => setState(() => _experience = level),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildDifficultySelector(ThemeData theme) {
    return Row(
      children: Difficulty.values.map((diff) {
        final isSelected = _difficulty == diff;
        final color = diff == Difficulty.easy
            ? AppColors.success
            : diff == Difficulty.medium
                ? AppColors.warning
                : AppColors.error;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: diff != Difficulty.hard ? 8 : 0,
              left: diff != Difficulty.easy ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => setState(() => _difficulty = diff),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.6)
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    diff.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: InterviewDuration.values.map((dur) {
        final isSelected = _duration == dur;
        return ChoiceChip(
          label: Text(dur.displayName),
          selected: isSelected,
          onSelected: (_) => setState(() => _duration = dur),
          selectedColor: AppColors.accent.withValues(alpha: 0.2),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.6)
                : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildResumeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (_hasStoredResume && _resumeFile == null)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Using your stored resume profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          if (_resumeFileName != null) ...[
            Row(
              children: [
                const Icon(Icons.insert_drive_file_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _resumeFileName!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isUploadingResume)
                  IconButton(
                    onPressed: () => setState(() {
                      _resumeFile = null;
                      _resumeFileName = null;
                      _resumeText = null;
                    }),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (_isUploadingResume) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Analyzing resume...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
          if (_resumeFileName == null && !_hasStoredResume) ...[
            OutlinedButton.icon(
              onPressed: _pickResume,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload Resume PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (_resumeFileName == null && _hasStoredResume) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickResume,
              icon: const Icon(Icons.upload_file_rounded, size: 16),
              label: const Text('Upload a different resume'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillController,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a skill (e.g., Flutter, Python)',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              IconButton(
                onPressed: _addSkill,
                icon: const Icon(Icons.add_circle_rounded,
                    color: AppColors.primary),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(
                    skill,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: AppColors.textMuted,
                  onDeleted: () => _removeSkill(skill),
                  backgroundColor: AppColors.surfaceLight,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_skills.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _mode == InterviewMode.skill
                    ? 'Add at least one skill to continue.'
                    : 'Skills are optional for this mode.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
