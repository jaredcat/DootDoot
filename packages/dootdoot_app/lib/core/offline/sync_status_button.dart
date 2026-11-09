import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pro_api/pro_api.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers.dart';
import 'drift/drift_offline_cache.dart';
import 'offline_write_coordinator.dart';

/// AppBar action showing offline / pending sync / conflict state.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proControllerProvider);
    if (!isPro) return const SizedBox.shrink();

    final status = ref.watch(syncStatusProvider);
    if (!status.offline && !status.hasPending) {
      return const SizedBox.shrink();
    }

    final icon = status.conflictCount > 0
        ? Symbols.warning_amber
        : status.offline
            ? Symbols.cloud_off
            : Symbols.cloud_upload;
    final tooltip = status.conflictCount > 0
        ? '${status.conflictCount} sync conflict(s)'
        : status.offline
            ? 'Offline'
            : '${status.pendingCount} change(s) waiting to sync';

    return IconButton(
      tooltip: tooltip,
      onPressed: () => _openSheet(context, ref),
      icon: Badge(
        isLabelVisible: status.hasPending,
        label: Text(
          '${status.conflictCount > 0 ? status.conflictCount : status.pendingCount}',
        ),
        child: Icon(icon),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    await ref.read(syncStatusProvider.notifier).refreshPending();
    if (!context.mounted) return;
    final status = ref.read(syncStatusProvider);
    final account = ref.read(activeAccountProvider);
    final cache = ref.read(offlineCacheProvider);
    List<Map<String, dynamic>> conflicts = const [];
    if (account != null && cache is DriftOfflineCache) {
      conflicts = await cache.conflictWritesAsync(account.id);
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sync status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  status.offline
                      ? 'You appear to be offline. Changes are saved on this '
                          'device and will sync when you are back online.'
                      : status.conflictCount > 0
                          ? 'Some changes conflict with the server. Choose which '
                              'version to keep.'
                          : status.pendingCount > 0
                              ? '${status.pendingCount} change(s) waiting to sync.'
                              : 'Everything is synced.',
                ),
                if (conflicts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Conflicts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...conflicts.map((op) {
                    final title = _conflictTitle(op);
                    final outboxId = op['_outboxId'] as int?;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: const Text('Tap to resolve'),
                      trailing: const Icon(Symbols.chevron_right),
                      onTap: outboxId == null
                          ? null
                          : () async {
                              Navigator.pop(sheetContext);
                              await showConflictDialog(
                                context,
                                ref,
                                outboxId: outboxId,
                                op: op,
                              );
                            },
                    );
                  }),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await ref.read(offlineWriteCoordinatorProvider).drain();
                    await ref.read(syncStatusProvider.notifier).refreshPending();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Retry sync'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _conflictTitle(Map<String, dynamic> op) {
    final entity = op['entity']?.toString() ?? 'task';
    final body = op['body'] is Map
        ? Map<String, dynamic>.from(op['body'] as Map)
        : <String, dynamic>{};
    final name = body['name'] ?? body['title'] ?? op['uid'] ?? entity;
    return '$entity: $name';
  }
}

Future<void> showConflictDialog(
  BuildContext context,
  WidgetRef ref, {
  required int outboxId,
  required Map<String, dynamic> op,
}) async {
  final body = op['body'] is Map
      ? Map<String, dynamic>.from(op['body'] as Map)
      : <String, dynamic>{};
  Map<String, dynamic>? server;
  final serverRaw = op['_conflictServerJson']?.toString();
  if (serverRaw != null && serverRaw.isNotEmpty) {
    try {
      final decoded = jsonDecode(serverRaw);
      if (decoded is Map) {
        server = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      server = null;
    }
  }

  final localSummary = body['name']?.toString() ??
      body['title']?.toString() ??
      op['uid']?.toString() ??
      'Your version';
  final serverSummary = server?['name']?.toString() ??
      server?['title']?.toString() ??
      'Server version';

  if (!context.mounted) return;
  final choice = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Resolve sync conflict'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This item changed on the server while you had a local edit. '
                'Choosing one version will discard the other.',
              ),
              const SizedBox(height: 16),
              Text(
                'Your version',
                style: Theme.of(dialogContext).textTheme.titleSmall,
              ),
              Text(localSummary),
              if (body['content'] != null || body['note'] != null)
                Text(
                  (body['content'] ?? body['note']).toString(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Text(
                'Server version',
                style: Theme.of(dialogContext).textTheme.titleSmall,
              ),
              Text(serverSummary),
              if (server?['content'] != null || server?['note'] != null)
                Text(
                  (server?['content'] ?? server?['note']).toString(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Text(
                'The version you do not choose will be permanently overwritten.',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'server'),
            child: const Text('Keep server'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'mine'),
            child: const Text('Keep mine'),
          ),
        ],
      );
    },
  );

  final coordinator = ref.read(offlineWriteCoordinatorProvider);
  if (choice == 'mine') {
    await coordinator.resolveKeepMine(outboxId);
  } else if (choice == 'server') {
    await coordinator.resolveKeepServer(outboxId);
  }
  await ref.read(syncStatusProvider.notifier).refreshPending();
}
