import 'export_builder.dart';
import 'export_data_source.dart';

/// Reads everything a user owns and returns an [ExportBundle] (M14 step 2).
///
/// A collection that cannot be read does not fail the export: it is skipped and
/// recorded in `notes` (shown in export-info.txt). Only the user document and
/// the profile list are essential, so errors there propagate.
class ExportCollector {
  ExportCollector(this._source, {this.maxDocsPerCollection = 20000});

  final ExportDataSource _source;
  final int maxDocsPerCollection;

  /// Sub-collections of `profiles/{id}` that hold the user's records.
  static const List<String> profileCollections = [
    'medications',
    'doses',
    'dailySummaries',
    'allergies',
    'pharmacies',
    'safetyWarnings',
    'vitals',
    'vitalsDaily',
    'symptoms',
    'prescribers',
    'appointments',
    'doctorNotes',
  ];

  Future<ExportBundle> collect({
    required String uid,
    required String appVersion,
    DateTime? now,
    void Function(String message)? onProgress,
  }) async {
    final notes = <String>[];
    onProgress?.call('account');
    final user = await _source.getUser(uid);
    final owned = await _source.listOwnedProfiles(uid);

    final profiles = <ExportProfile>[];
    for (final p in owned) {
      onProgress?.call('profile ${p.id}');
      final collections = <String, List<ExportDoc>>{};

      for (final name in profileCollections) {
        onProgress?.call('${p.id}/$name');
        final docs = await _read('profiles/${p.id}/$name', name, p.id, notes);
        collections[name] = [
          for (final d in docs) ExportDoc(path: '$name/${d.id}', data: d.data),
        ];
      }

      // Stock history lives under each medication.
      final events = <ExportDoc>[];
      for (final m in collections['medications'] ?? const <ExportDoc>[]) {
        final docs = await _read(
          'profiles/${p.id}/medications/${m.id}/inventoryEvents',
          'inventoryEvents(${m.id})',
          p.id,
          notes,
        );
        for (final d in docs) {
          events.add(
            ExportDoc(
              path: 'medications/${m.id}/inventoryEvents/${d.id}',
              data: d.data,
            ),
          );
        }
      }
      collections['inventoryEvents'] = events;

      profiles.add(
        ExportProfile(profileId: p.id, data: p.data, collections: collections),
      );
    }

    return ExportBundle(
      generatedAt: (now ?? DateTime.now()).toUtc(),
      appVersion: appVersion,
      userId: uid,
      userData: user,
      profiles: profiles,
      notes: notes,
    );
  }

  Future<List<RawDoc>> _read(
    String path,
    String label,
    String profileId,
    List<String> notes,
  ) async {
    try {
      final r = await _source.readCollection(
        path,
        maxDocs: maxDocsPerCollection,
      );
      if (r.truncated) {
        notes.add(
          'Profile $profileId, $label: only the first '
          '$maxDocsPerCollection records were exported.',
        );
      }
      return r.docs;
    } catch (e) {
      notes.add('Profile $profileId, $label: could not be read ($e).');
      return const [];
    }
  }
}
