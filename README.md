# DootDoot

Unofficial Flutter companion for [tududi](https://tududi.com).

Connect to **tududi Cloud** (`https://app.tududi.com`) or any self-hosted tududi instance. DootDoot is not affiliated with tududi or Chris Veleris — your data stays on *your* tududi server.

## Free vs Pro

This repository is the **free / community** client (open-core):

- Cloud / self-host connect, Today / Upcoming / Inbox
- Tasks, projects, areas, notes, search
- **One account**

**Pro** enhancements (calendar, goals, habits, boards, offline cache, widgets, unlimited accounts, IAP).

## Structure

```text
apps/mobile/              Free Flutter entrypoint
packages/dootdoot_app/    Shared UI shell
packages/pro_api/         Pro interfaces + free host (1-account cap)
packages/tududi_api/      Typed tududi REST client
packages/design/          Theme and shared UI tokens
docs/                     Privacy policy (GitHub Pages)
```

**Privacy policy:** <https://jaredcat.github.io/DootDoot/privacy-policy/>
**Terms of Service:** <https://jaredcat.github.io/DootDoot/terms/>

## Setup

```bash
git config core.hooksPath hooks
flutter pub get
cd apps/mobile && flutter run
```

Requires Flutter 3.47+ / Dart 3.13+.

Local pre-commit runs `dart format` and `flutter analyze --fatal-infos` on staged Dart. Skip with `SKIP_HOOKS=1`.

## License

Mozilla Public License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
