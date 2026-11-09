import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_api/pro_api.dart';
import 'package:tududi_api/tududi_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, required this.kind, this.addingAccount = false});

  /// `cloud` or `self`
  final String kind;
  final bool addingAccount;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  final _urlFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _tokenFocus = FocusNode();

  bool _useApiToken = false;
  bool _busy = false;
  bool _loginSucceeded = false;
  String? _error;
  List<Map<String, dynamic>> _oidcProviders = const [];
  late String _kind;

  bool get _isCloud => _kind == 'cloud';

  @override
  void initState() {
    super.initState();
    _kind = widget.kind == 'self' ? 'self' : 'cloud';
    _urlController = TextEditingController(
      text: _isCloud ? TududiUrls.cloud : 'https://',
    );
    if (_isCloud) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOidc());
    }
  }

  void _setKind(String kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _error = null;
      _oidcProviders = const [];
      if (_isCloud) {
        _urlController.text = TududiUrls.cloud;
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadOidc());
      } else if (_urlController.text.trim() == TududiUrls.cloud ||
          _urlController.text.trim().isEmpty) {
        _urlController.text = 'https://';
      }
    });
  }

  Future<void> _loadOidc() async {
    try {
      final factory = const TududiClientFactory();
      final client = factory.create(
        TududiClientConfig(baseUrl: TududiUrls.cloud),
      );
      final providers = await client.listOidcProviders();
      if (mounted) setState(() => _oidcProviders = providers);
    } catch (_) {
      // Optional.
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _urlFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _tokenFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.addingAccount) {
      final allowed = await ensureCanAddAccount(
        context,
        ref,
        accountCount: ref.read(accountsProvider).length,
      );
      if (!allowed || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = ref.read(accountSessionProvider);
      if (_useApiToken) {
        await session.signInWithApiToken(
          baseUrl: _urlController.text.trim(),
          token: _tokenController.text.trim(),
        );
      } else {
        await session.signInWithPassword(
          baseUrl: _urlController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      ref.read(accountsProvider.notifier).refresh();
      final id = ref.read(accountStoreProvider).activeAccountId;
      if (id != null) {
        await ref.read(activeAccountIdProvider.notifier).switchTo(id);
      }
      if (!mounted) return;
      // Rebuild so the autofill group commits on dispose. Navigating in the
      // same turn would dispose it while it is still set to cancel.
      setState(() => _loginSucceeded = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      context.go('/today');
    } on TududiApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openOidc(String slug) async {
    final base = TududiUrls.normalizeBaseUrl(_urlController.text.trim());
    final url = Uri.parse('$base/api/oidc/auth/$slug');
    await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Complete sign-in in the browser, then return here and use an API token from Profile → API Keys.',
        ),
      ),
    );
    setState(() => _useApiToken = true);
  }

  bool get _multiAccountLocked {
    if (!widget.addingAccount) return false;
    ref.watch(proControllerProvider);
    return !canAddAccount(
      accountCount: ref.watch(accountsProvider).length,
      controller: ref.read(proControllerProvider.notifier),
    );
  }

  Widget _buildProOnlyAddAccount(BuildContext context) {
    final controller = ref.watch(proControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add account'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: ProBadge()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Multiple accounts with Pro',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Free includes one Tududi account. DootDoot Pro unlocks unlimited '
              'accounts so you can switch between Cloud and self-hosted '
              'servers — plus calendar, goals, habits, boards, and offline cache.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (controller.canPurchase) ...[
              FilledButton(
                onPressed: () async {
                  await controller.purchase();
                },
                child: const Text('Unlock Pro'),
              ),
              TextButton(
                onPressed: () async {
                  await controller.restore();
                },
                child: const Text('Restore purchase'),
              ),
            ] else
              Text(
                'Get DootDoot Pro to add another account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_multiAccountLocked) {
      return _buildProOnlyAddAccount(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.addingAccount
              ? 'Add account'
              : (_isCloud ? 'Tududi Cloud' : 'Self-hosted'),
        ),
      ),
      // One group, and every field built up front (not a lazy list). iOS,
      // Android, and the web engine only pair a login when the username and
      // password exist together. Commit the save prompt after a successful
      // sign-in; cancel it if the user leaves without signing in.
      body: AutofillGroup(
        onDisposeAction: _loginSucceeded
            ? AutofillContextAction.commit
            : AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Unofficial app. Data stays on the Tududi server you connect to.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'cloud',
                      label: Text('Tududi Cloud'),
                      icon: Icon(Icons.cloud_outlined),
                    ),
                    ButtonSegment(
                      value: 'self',
                      label: Text('Self-hosted'),
                      icon: Icon(Icons.dns_outlined),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _busy
                      ? null
                      : (selected) => _setKind(selected.first),
                ),
                const SizedBox(height: 16),
                if (!_isCloud) ...[
                  TextFormField(
                    controller: _urlController,
                    focusNode: _urlFocus,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://tududi.example.com',
                    ),
                    keyboardType: TextInputType.url,
                    autofillHints: const [AutofillHints.url],
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    onFieldSubmitted: (_) {
                      (_useApiToken ? _tokenFocus : _emailFocus).requestFocus();
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      try {
                        TududiUrls.normalizeBaseUrl(v);
                      } catch (_) {
                        return 'Invalid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sign in with API token'),
                  subtitle: const Text('Use for SSO-only servers'),
                  value: _useApiToken,
                  onChanged: (v) => setState(() => _useApiToken = v),
                ),
                if (_useApiToken)
                  TextFormField(
                    controller: _tokenController,
                    focusNode: _tokenFocus,
                    decoration: const InputDecoration(
                      labelText: 'API token',
                      hintText: 'tt_…',
                    ),
                    keyboardType: TextInputType.text,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  )
                else ...[
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@example.com',
                    ),
                    // First hint wins on iOS and web. `username` is what 1Password,
                    // iCloud Keychain, and Google Password Manager pair with a
                    // password; `email` is an extra hint for Android.
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    decoration: const InputDecoration(labelText: 'Password'),
                    // Text, not visiblePassword: that is the keyboard type iOS
                    // pairs with a password content type. obscureText marks it secret.
                    keyboardType: TextInputType.text,
                    autofillHints: const [AutofillHints.password],
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    spellCheckConfiguration:
                        const SpellCheckConfiguration.disabled(),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ],
                if (_oidcProviders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Or continue with',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._oidcProviders.map((p) {
                    final slug = (p['slug'] ?? '').toString();
                    final name = (p['name'] ?? slug).toString();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: _busy || slug.isEmpty
                            ? null
                            : () => _openOidc(slug),
                        child: Text('Sign in with $name'),
                      ),
                    );
                  }),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.addingAccount ? 'Add account' : 'Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
