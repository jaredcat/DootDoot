import 'package:dootdoot_design/dootdoot_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tududi_api/tududi_api.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [DootColors.foam, DootColors.cloud, Color(0xFFDDEEEF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DootSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'DootDoot',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DootSpacing.sm),
                Text(
                  'An unofficial companion for Tududi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: DootColors.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DootSpacing.md),
                Text(
                  'Connect to Tududi Cloud or your self-hosted server. '
                  'Not affiliated with tududi or Chris Veleris — your data stays on your server.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: DootColors.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.push('/sign-in?kind=cloud'),
                  child: const Text('Continue with Tududi Cloud'),
                ),
                const SizedBox(height: DootSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.push('/sign-in?kind=self'),
                  child: const Text('Use self-hosted server'),
                ),
                const SizedBox(height: DootSpacing.md),
                Text(
                  TududiUrls.cloud,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
