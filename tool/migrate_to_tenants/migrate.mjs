#!/usr/bin/env node
/**
 * NSK Firestore migration: top-level collections → tenants/nsk/* subcollections.
 * DEFAULT: dry-run. Pass --execute to write. DO NOT run against production
 * without a verified backup.
 */
import { createWriteStream } from 'fs';
import { mkdir, writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import admin from 'firebase-admin';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const COLLECTIONS = [
  'site',
  'news',
  'programs',
  'products',
  'gallery',
  'banners',
  'media',
  'events',
  'shiurim',
  'famous',
  'history',
  'tour',
  'touristInfo',
  'leads',
  'donations',
  'subscribers',
  'orders',
  'rsvps',
];

const TENANT_ID = 'nsk';

function parseArgs(argv) {
  const execute = argv.includes('--execute');
  const backupDir =
    argv.find((a) => a.startsWith('--backup-dir='))?.split('=')[1] ??
    path.join(__dirname, 'backup', new Date().toISOString().replace(/[:.]/g, '-'));
  return { execute, backupDir };
}

async function listStorageObjects(bucket, prefix = '') {
  const names = [];
  let pageToken;
  do {
    const [files, , response] = await bucket.getFiles({
      prefix,
      maxResults: 1000,
      pageToken,
    });
    for (const f of files) names.push(f.name);
    pageToken = response?.nextPageToken;
  } while (pageToken);
  return names;
}

async function exportCollection(db, name) {
  const snap = await db.collection(name).get();
  return snap.docs.map((d) => ({ id: d.id, data: d.data() }));
}

async function stepBackup(db, bucket, backupDir) {
  await mkdir(backupDir, { recursive: true });
  const manifest = { collections: {}, storage: [] };
  for (const name of COLLECTIONS) {
    const docs = await exportCollection(db, name);
    manifest.collections[name] = docs.length;
    await writeFile(
      path.join(backupDir, `${name}.json`),
      JSON.stringify(docs, null, 2),
      'utf8',
    );
    console.log(`[backup] ${name}: ${docs.length} docs`);
  }
  if (bucket) {
    manifest.storage = await listStorageObjects(bucket, 'site/');
    await writeFile(
      path.join(backupDir, 'storage-objects.json'),
      JSON.stringify(manifest.storage, null, 2),
      'utf8',
    );
    console.log(`[backup] storage objects: ${manifest.storage.length}`);
  }
  await writeFile(
    path.join(backupDir, 'manifest.json'),
    JSON.stringify(manifest, null, 2),
    'utf8',
  );
  return manifest;
}

async function stepCopy(db, execute) {
  const tenantRef = db.collection('tenants').doc(TENANT_ID);
  for (const name of COLLECTIONS) {
    const src = await db.collection(name).get();
    console.log(`[copy] ${name}: ${src.size} docs → tenants/${TENANT_ID}/${name}`);
    if (!execute) continue;
    const dest = tenantRef.collection(name);
    const batchSize = 400;
    let batch = db.batch();
    let n = 0;
    for (const doc of src.docs) {
      batch.set(dest.doc(doc.id), doc.data());
      n++;
      if (n % batchSize === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (n % batchSize !== 0) await batch.commit();
  }
}

async function stepVerify(db) {
  const report = {};
  for (const name of COLLECTIONS) {
    const top = (await db.collection(name).get()).size;
    const sub = (
      await db.collection('tenants').doc(TENANT_ID).collection(name).get()
    ).size;
    report[name] = { topLevel: top, tenant: sub, ok: top === sub };
    console.log(`[verify] ${name}: top=${top} tenant=${sub} ${top === sub ? 'OK' : 'MISMATCH'}`);
  }
  return report;
}

async function stepSetMigrated(db, execute) {
  console.log(`[flag] tenants/${TENANT_ID}.migrated = true`);
  if (!execute) return;
  await db.collection('tenants').doc(TENANT_ID).set(
    { migrated: true, migratedAt: new Date().toISOString() },
    { merge: true },
  );
}

async function main() {
  const { execute, backupDir } = parseArgs(process.argv.slice(2));
  console.log(execute ? 'MODE: EXECUTE' : 'MODE: dry-run (pass --execute to write)');

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON path.');
    process.exit(1);
  }

  admin.initializeApp();
  const db = admin.firestore();
  const bucket = admin.storage().bucket();

  console.log('Step A: backup export');
  await stepBackup(db, bucket, backupDir);

  console.log('Step B: copy to tenants/nsk/...');
  await stepCopy(db, execute);

  console.log('Step C: verify counts');
  const verify = await stepVerify(db);
  const bad = Object.values(verify).filter((v) => !v.ok);
  if (bad.length) {
    console.error('Verification failed — not setting migrated flag.');
    process.exit(2);
  }

  console.log('Step D: set migrated flag');
  await stepSetMigrated(db, execute);

  console.log('Done.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
