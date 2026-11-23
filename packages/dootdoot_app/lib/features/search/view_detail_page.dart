import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tududi_api/tududi_api.dart';

import '../../core/providers.dart';
import 'search_criteria.dart';
import 'search_page.dart';
import 'views_page.dart';

final viewDetailProvider = FutureProvider.family<TududiView, String>((
  ref,
  uid,
) async {
  final client = await ref.watch(tududiClientProvider.future);
  if (client == null) throw TududiApiException(message: 'Not signed in');
  return client.getView(uid);
});

class ViewDetailPage extends ConsumerWidget {
  const ViewDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(viewDetailProvider(uid));

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (view) {
        return SearchPage(
          initial: SearchCriteria.fromView(view),
          viewUid: uid,
          viewName: view.name,
          isPinned: view.isPinned,
          onPinChanged: () {
            ref.invalidate(viewDetailProvider(uid));
            ref.invalidate(viewsProvider);
          },
        );
      },
    );
  }
}
