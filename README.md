# DootDoot

Unofficial Flutter companion for [Tududi](https://tududi.com) v2.

Connect to **Tududi Cloud** (`https://app.tududi.com`) or any self-hosted Tududi instance. DootDoot is not affiliated with tududi or Chris Veleris — your data stays on *your* Tududi server.

## Free vs Pro

This repository is the **free / community** client (open-core):

- Cloud / self-host connect, Today / Upcoming / Inbox
- Tasks, projects, areas, notes, search
- **One account**

**Pro** enhancements (calendar, goals, habits, boards, offline cache, widgets, unlimited accounts, IAP) live in the private `pro/` sibling and ship only in the official App Store / Play build. They are not part of this source tree — flipping free feature flags will not unlock them.

## Structure

```text
apps/mobile/              Free Flutter entrypoint
packages/dootdoot_app/    Shared UI shell
packages/pro_api/         Pro interfaces + free host (1-account cap)
packages/tududi_api/      Typed Tududi REST client
packages/design/          Theme and shared UI tokens
docs/                     Privacy, store checklist
```

Local layout (both checkouts side by side):

```text
dootdoot/
  free/                   # this repo (public)
  pro/                    # private store / Pro overlay
  dootdoot.code-workspace
```

## Setup

```bash
flutter pub get
cd apps/mobile && flutter run
```

Requires Flutter 3.47+ / Dart 3.13+.

For the official store / Pro build, use the sibling `pro/` checkout and run that app (it path-depends on these packages).

## License

Mozilla Public License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).
