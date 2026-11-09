import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  bool _busy = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(tududiClientProvider.future);
      if (client == null) return;
      final result = await client.search(query.trim());
      setState(() => _result = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = (_result?['tasks'] as List?) ?? const [];
    final projects = (_result?['projects'] as List?) ?? const [];
    final notes = (_result?['notes'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks, projects, notes…',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => _search(_controller.text),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Symbols.search),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                if (tasks.isNotEmpty) ...[
                  const ListTile(title: Text('Tasks')),
                  ...tasks.whereType<Map>().map((t) {
                    final uid = t['uid']?.toString();
                    final name = (t['name'] ?? t['original_name'] ?? 'Task')
                        .toString();
                    return ListTile(
                      leading: const Icon(Symbols.check_circle),
                      title: Text(name),
                      onTap: uid == null
                          ? null
                          : () => context.push('/task/$uid'),
                    );
                  }),
                ],
                if (projects.isNotEmpty) ...[
                  const ListTile(title: Text('Projects')),
                  ...projects.whereType<Map>().map((p) {
                    final uid = p['uid']?.toString();
                    return ListTile(
                      leading: const Icon(Symbols.folder),
                      title: Text((p['name'] ?? 'Project').toString()),
                      onTap: uid == null
                          ? null
                          : () => context.push('/more/projects/$uid'),
                    );
                  }),
                ],
                if (notes.isNotEmpty) ...[
                  const ListTile(title: Text('Notes')),
                  ...notes.whereType<Map>().map((n) {
                    final uid = n['uid']?.toString();
                    return ListTile(
                      leading: const Icon(Symbols.notes),
                      title: Text(
                        (n['title'] ?? n['name'] ?? 'Note').toString(),
                      ),
                      onTap: uid == null
                          ? null
                          : () => context.push('/more/notes/$uid'),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
