# Node.js security upgrade report

Date: 2026-10-23

## Repository Node usage

This repo is primarily **Flutter** (web deploy via GitHub Pages / Amvera Docker). Node.js is used only for the one-off Firestore migration utility in `tool/migrate_to_tenants/`.

There is **no Next.js** application in this repository.

## Node version references

| Location | Before | After |
|----------|--------|-------|
| `Dockerfile` | `debian:bookworm-slim` + Flutter 3.47.4 (no Node image) | unchanged |
| `.nvmrc` | *(none)* | `24.22.1` |
| `.node-version` | *(none)* | *(none)* |
| `tool/migrate_to_tenants/package.json` `engines` | *(none)* | `node: ">=24"` |
| `tool/migrate_to_tenants/README.md` | Node.js 18+ | Node.js 24+ |
| `.github/workflows/deploy-github-pages.yml` | Flutter only | unchanged |
| `.github/workflows/node-migrate-tool.yml` | *(none)* | `node-version: 24.22.1` |

Local toolchain used for verification: **Node v24.22.1** (Active LTS Krypton, security release 2026-10-20).

## npm audit (`tool/migrate_to_tenants`)

| | Low | Moderate | High | Critical |
|---|-----|----------|------|----------|
| **Before** (`firebase-admin` ^13.0.0) | 0 | 8 | 0 | 0 |
| **After** (`firebase-admin` ^14.5.0) | 0 | 0 | 0 | 0 |

### Remediation

- `npm audit fix` alone did not clear moderate issues (fix required `firebase-admin` major bump).
- Upgraded direct dependency `firebase-admin` from `^13.0.0` to `^14.5.0` (patched transitive `uuid` / Google client stack).
- No `npm audit fix --force` and no `overrides` were required after the upgrade.

## Build and checks

| Check | Result |
|-------|--------|
| `cd tool/migrate_to_tenants && npm ci && npm run build` | **pass** (`node --check migrate.mjs`) |
| `npm audit --audit-level=high` | **pass** (0 vulnerabilities) |
| Flutter `npm run build` at repo root | N/A (no root `package.json`) |

## Dependency lockfile

- Added `tool/migrate_to_tenants/package-lock.json` for reproducible CI (`npm ci`).
- Added `**/node_modules/` to `.gitignore`.
