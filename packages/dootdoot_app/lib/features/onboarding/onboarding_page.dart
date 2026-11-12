import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onBrand = Colors.white;
    final onBrandMuted = Colors.white.withValues(alpha: 0.82);

    return Scaffold(
      backgroundColor: DootColors.brand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DootSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(child: DootBrandAssets.markImage(size: 112)),
              const SizedBox(height: DootSpacing.lg),
              Center(child: DootBrandAssets.wordmarkImage(height: 44)),
              const SizedBox(height: DootSpacing.md),
              Text(
                'An unofficial companion for tududi',
                style: theme.textTheme.titleMedium?.copyWith(color: onBrand),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DootSpacing.md),
              Text(
                'Connect to tududi Cloud or your self-hosted server.',
                style: theme.textTheme.bodyMedium?.copyWith(color: onBrandMuted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: onBrand,
                  foregroundColor: DootColors.brand,
                ),
                onPressed: () => context.push('/sign-in?kind=cloud'),
                child: const Text('Continue with tududi Cloud'),
              ),
              const SizedBox(height: DootSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: onBrand,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
                ),
                onPressed: () => context.push('/sign-in?kind=self'),
                child: const Text('Use self-hosted server'),
              ),
              const SizedBox(height: DootSpacing.md),
              Text(
                'Not affiliated with tududi or Chris Veleris — your data stays on your server.',
                style: theme.textTheme.bodySmall?.copyWith(color: onBrandMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
