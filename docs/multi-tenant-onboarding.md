# Multi-tenant onboarding (phase 2)

## Flow

1. **Super-admin** signs in at `/admin` (Firebase Auth when configured).
2. Open **Communities** (`/admin/communities`) to see NSK, bundled seeds (e.g. `tomsk`), browser-local tenants, and Firestore tenants (when Firebase is configured).
3. **New community** (`/admin/communities/new` — Hebrew title *פתיחת קהילה חדשה*): fill multilingual name, city, slug, colors, logo, contacts, languages, about, optional photos, source credit.
4. On submit:
   - **Firebase configured + signed in**: writes `tenants/{id}` and image docs under `tenants/{id}/media` (same pattern as site media).
   - **Otherwise**: saves a local package for `?tenant=<id>` in this browser and offers **Download tenant package** (JSON with base64 images).
5. **Ship a bundled tenant**: place files under `assets/tenants/<id>/` (`tenant.json` + images) and register the folder in `pubspec.yaml`. Run `dart run tool/tenants/import_seed.dart` to unpack a downloaded package or a sample folder.

## Preview

Use `?tenant=<id>` on any host (e.g. `/#/?tenant=tomsk`). Unknown ids show a friendly “community not found” screen — never NSK content.

## Manual steps (owner approval required)

| Step | Notes |
|------|--------|
| **Amvera subdomain / custom domain** | Configure DNS and Amvera routing for `*.jewishsib.ru` or per-community hosts. |
| **Firebase Auth admin** | Create admin user; set **custom claim** `superAdmin: true` (see `firebase/firestore.rules.multitenant`). |
| **Deploy Firestore rules** | Publish `firebase/firestore.rules.multitenant` (not done from this repo in phase 2). |
| **Deploy Storage rules** | If/when Storage is used for tenant assets, deploy multitenant storage rules separately. |
| **Migration** | Run `tool/migrate_to_tenants` only after rules and owner sign-off — **do not** run from CI or agents. |
| **Kaddish** | Link each community’s Kaddish board / service id in tenant config when going live. |

## Sample tenant `tomsk`

Bundled under `assets/tenants/tomsk/` from `tomsk-sample` via `import_seed`. Source credit on About/footer: *Источник: jewtomsk.ru, feor.ru*.
