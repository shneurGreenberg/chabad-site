/// Who wins when IndexedDB and Firestore both have a site snapshot.
///
/// Guests always take the published cloud copy. A local stamp of
/// `updatedAt: now` after persist used to make the next visit skip Firestore.
bool localAdminSnapshotWins({
  required bool signedIn,
  required bool diskHadSnapshot,
  DateTime? localUpdatedAt,
  DateTime? cloudUpdatedAt,
  required int localSeq,
  required int cloudSeq,
}) {
  if (!signedIn) return false;
  if (!diskHadSnapshot) return false;
  if (localUpdatedAt != null && cloudUpdatedAt != null) {
    final delta = localUpdatedAt.difference(cloudUpdatedAt);
    if (delta.abs() > const Duration(seconds: 2)) {
      return localUpdatedAt.isAfter(cloudUpdatedAt);
    }
  } else if (localUpdatedAt != null && cloudUpdatedAt == null) {
    return true;
  }
  return localSeq > cloudSeq;
}
