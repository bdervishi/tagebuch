import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Keys für Tests.
const Key onboardingSkipKey = Key('onboarding-skip');
const Key onboardingNextKey = Key('onboarding-next');

/// Einmaliges Onboarding in vier Textschritten (docs/03 Abschnitt 3):
/// Gerätecode und Backup-Hinweis, Mikrofon, Sprache, Erinnerung.
/// Überspringbar; [onFinished] wird bei "Überspringen" und am Ende gerufen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _stepCount = 4;

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _stepCount - 1) {
      widget.onFinished();
      return;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLast = _page == _stepCount - 1;
    final steps = [
      (
        icon: Icons.lock_outline,
        title: l10n.onboardingStep1Title,
        body: l10n.onboardingStep1Body,
      ),
      (
        icon: Icons.mic_none,
        title: l10n.onboardingStep2Title,
        body: l10n.onboardingStep2Body,
      ),
      (
        icon: Icons.translate,
        title: l10n.onboardingStep3Title,
        body: l10n.onboardingStep3Body,
      ),
      (
        icon: Icons.notifications_none,
        title: l10n.onboardingStep4Title,
        body: l10n.onboardingStep4Body,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (!isLast)
            TextButton(
              key: onboardingSkipKey,
              onPressed: widget.onFinished,
              child: Text(l10n.onboardingSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    children: [
                      Icon(
                        step.icon,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          step.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.body,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingStepOf(_page + 1, _stepCount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: onboardingNextKey,
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      isLast ? l10n.onboardingDone : l10n.onboardingNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
