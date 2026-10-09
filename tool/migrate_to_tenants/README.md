# NSK tenant migration (NOT run against live by default)

Copies top-level Firestore collections into `tenants/nsk/{collection}` and sets `tenants/nsk.migrated = true` after verification.

**Default is dry-run** (no writes). You must pass `--execute` to copy data and set the flag.

## Prerequisites

- Node.js 18+
- A Firebase **service account** JSON with read/write access to the project
- **Do not** point this at production until you have reviewed backups and rules

## Setup

```bash
cd tool/migrate_to_tenants
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

## Commands

Dry-run (backup export + log planned copies; no writes):

```bash
node migrate.mjs
```

Custom backup directory:

```bash
node migrate.mjs --backup-dir=./my-backup-2026-10-09
```

Execute migration (writes copies + `migrated` flag):

```bash
node migrate.mjs --execute
```

## Steps

1. **A** — Full JSON export of listed collections + `storage-objects.json` under `site/`
2. **B** — Copy each collection into `tenants/nsk/{name}`
3. **C** — Compare document counts (top-level vs tenant subcollection)
4. **D** — Set `migrated: true` on `tenants/nsk` (only if step C passes)

## After migration

Deploy updated Firestore rules from `firebase/firestore.rules.multitenant` when ready. The Flutter app reads `migrated` and switches NSK reads/writes to namespaced paths.
