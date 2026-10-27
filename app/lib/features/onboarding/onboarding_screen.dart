import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_services.dart';
import '../../widgets/reveal.dart';

/// Keys für Tests.
const Key onboardingSkipKey = Key('onboarding-skip');
const Key onboardingNextKey = Key('onboarding-next');

/// Einmaliges Onboarding in Textschritten (docs/03 Abschnitt 3): Schutz und
/// Backup-Hinweis, Mikrofon, Sprache, Erinnerung. Auf dem Web (D16) voran ein
/// Schritt "Als App installieren", solange die PWA nicht installiert läuft,
/// und ein angepasster erster Schritt (Daten im Browser, Backup Pflicht).
/// Überspringbar; [onFinished] wird bei "Überspringen" und am Ende gerufen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int stepCount) {
    if (_page >= stepCount - 1) {
      widget.onFinished();
      return;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: Motion.page, curve: Motion.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final features = ref.watch(platformFeaturesProvider);
    final showInstall = features.isWeb && !features.isStandalone;
    final steps = [
      if (showInstall)
        (
          icon: Icons.add_to_home_screen,
          title: l10n.onboardingInstallTitle,
          body: features.isIos
              ? l10n.onboardingInstallBodyIos
              : l10n.onboardingInstallBodyAndroid,
        ),
      (
        icon: Icons.lock_outline,
        title: features.isWeb
            ? l10n.onboardingStep1TitleWeb
            : l10n.onboardingStep1Title,
        body: features.isWeb
            ? l10n.onboardingStep1BodyWeb
            : l10n.onboardingStep1Body,
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
        body: features.isWeb ? l10n.reminderWebNote : l10n.onboardingStep4Body,
      ),
    ];
    final stepCount = steps.length;
    final isLast = _page == stepCount - 1;

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
                  // Erstes Mal gesehen: Symbol, Titel und Text erscheinen
                  // gestaffelt (docs/12 Abschnitt 2, "selten").
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    children: [
                      Reveal(
                        index: 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              step.icon,
                              size: 34,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Reveal(
                        index: 1,
                        child: Semantics(
                          header: true,
                          child: Text(
                            step.title,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Reveal(
                        index: 2,
                        child: Text(
                          step.body,
                          style: theme.textTheme.bodyLarge,
                        ),
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
                  // Fortschritt als Punkte (aktiver Punkt wird zum Strich);
                  // der Text darunter bleibt für Screenreader und Tests.
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < stepCount; i++)
                          AnimatedContainer(
                            duration: Motion.quick,
                            curve: Motion.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onboardingStepOf(_page + 1, stepCount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: onboardingNextKey,
                    onPressed: () => _next(stepCount),
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
