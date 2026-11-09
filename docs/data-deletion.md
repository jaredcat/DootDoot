---
layout: default
title: Request data deletion
permalink: /data-deletion/
---

# Request data deletion — DootDoot

DootDoot is an unofficial companion app for tududi. It does **not** operate a DootDoot backend that stores your tasks, notes, or projects.

## What DootDoot stores

- **On this device only:** server URL, account metadata, API tokens / session material, and (if Pro offline sync is enabled) a local cache of tasks and related data, plus local notification schedules.
- **Not stored by DootDoot:** your tududi task/project/note content lives on the tududi server you configure ([tududi Cloud](https://app.tududi.com) or self-hosted). Purchases are handled by Google Play / Apple; DootDoot only keeps a local “Pro unlocked” flag.

## How to delete data DootDoot holds on your device

1. Open **DootDoot**.
2. Go to **Settings → Accounts** (or Sign out / Accounts).
3. **Remove** the account (or Sign out, then remove).

This deletes local credentials, offline cache for that account, and cancels pending local notifications for it. No retention period — removal is immediate on the device.

Uninstalling DootDoot also removes app-local data from that device.

## How to delete data on your tududi server

DootDoot cannot delete server-side tududi data on your behalf beyond what the tududi API allows while you are signed in.

- **tududi Cloud:** use Profile / account settings on [app.tududi.com](https://app.tududi.com) to delete or export your account per tududi’s process.
- **Self-hosted:** ask your server admin, or use your instance’s account deletion tools.

## Contact

Questions about DootDoot data deletion: [open an issue](https://github.com/jaredcat/dootdoot/issues).
