import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/app_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/form_card.dart';
import '../utils/page_transitions.dart';
import 'loading_screen.dart';

class Form2Screen extends StatefulWidget {
  const Form2Screen({super.key});

  @override
  State<Form2Screen> createState() => _Form2ScreenState();
}

class _Form2ScreenState extends State<Form2Screen> {
  List<FaoQuestion> _questions = [];
  // question text → selected option value
  final Map<String, String?> _answers = {};

  bool _loadingQuestions = true;
  bool _submitting = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _loadingQuestions = true;
      _fetchError = null;
    });
    try {
      final questions = await ApiService.getFaoQuestions(AppSession.userId);
      setState(() {
        _questions = questions;
        for (final q in questions) {
          _answers.putIfAbsent(q.question, () => null);
        }
        _loadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _fetchError = e.toString().replaceFirst('Exception: ', '');
        _loadingQuestions = false;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final hasUnanswered = _answers.values.any((v) => v == null);
    if (hasUnanswered) {
      _showSnack('Please answer all questions before submitting.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.postFaoAnswers(
        userId: AppSession.userId,
        answers: _answers.map((k, v) => MapEntry(k, v!)),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          FadeOnlyPageRoute(page: const LoadingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          StepHeader(
            currentStep: 2,
            totalSteps: 2,
            title: 'Answer These Questions',
            subtitle: 'Select the most accurate option for your farm',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: _buildBody()),
          if (!_loadingQuestions && _fetchError == null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: CustomButton(
                  label: 'Submit',
                  trailingIcon: Icons.check_rounded,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingQuestions) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.forestMid,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading questions…',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      );
    }

    if (_fetchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.inkMuted),
              const SizedBox(height: 16),
              Text(
                _fetchError!,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Retry',
                leadingIcon: Icons.refresh_rounded,
                onPressed: _fetchQuestions,
                fullWidth: false,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          for (int i = 0; i < _questions.length; i++) ...[
            _QuestionCard(
              index: i + 1,
              question: _questions[i],
              value: _answers[_questions[i].question],
              onChanged: (v) =>
                  setState(() => _answers[_questions[i].question] = v),
            )
                .animate(delay: (i * 70).ms)
                .fadeIn(duration: 400.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
            if (i != _questions.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final FaoQuestion question;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.forestMid,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$index',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.question,
                  style: AppTextStyles.headingS.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.forestMid,
            ),
            hint: Text(
              'Select an option',
              style: AppTextStyles.bodyM.copyWith(color: AppColors.inkMuted),
            ),
            style: AppTextStyles.bodyM,
            borderRadius: BorderRadius.circular(14),
            decoration: const InputDecoration(),
            items: question.options
                .map(
                  (o) => DropdownMenuItem(value: o, child: Text(o)),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
