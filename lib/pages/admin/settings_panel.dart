import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models.dart';
import '../../services/geo.dart';
import '../../services/location_zmanim.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _query = TextEditingController();
  final _mapsKey = TextEditingController();
  List<GeoPlace> _results = const [];
  bool _searching = false;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AppRepository>();
    _query.text = repo.location.query;
    _mapsKey.text = repo.googleMapsApiKey;
  }

  @override
  void dispose() {
    _query.dispose();
    _mapsKey.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final loc = context.loc;
    setState(() => _searching = true);
    try {
      final places = await LocationZmanimApi.searchCity(
        _query.text,
        lang: loc.lang,
      );
      if (!mounted) return;
      setState(() => _results = places);
      if (places.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('admin.settings.noResults'))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.settings.error'))),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useGps() async {
    final loc = context.loc;
    setState(() => _locating = true);
    try {
      final (lat, lon) = await currentPosition();
      final place = await LocationZmanimApi.fromCoordinates(lat, lon, lang: loc.lang);
      if (!mounted) return;
      await _apply(place);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.settings.geoError'))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _apply(GeoPlace place) async {
    final loc = context.loc;
    final repo = context.read<AppRepository>();
    setState(() => _saving = true);
    try {
      await repo.setLocation(SiteLocation(
        cityName: place.name,
        query: place.label,
        latitude: place.latitude,
        longitude: place.longitude,
        timezone: place.timezone,
      ));
      if (!mounted) return;
      _query.text = place.label;
      setState(() => _results = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.settings.saved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.settings.timesError'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final site = context.watch<AppRepository>().location;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('admin.settings'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text(loc.t('admin.settings.subtitle'),
              style: const TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(loc.t('admin.persist.note'),
                style: const TextStyle(color: AppColors.muted, height: 1.45, fontSize: 13.5)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: loc.t('admin.settings.city'),
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: Text(loc.t('admin.settings.search')),
              ),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useGps,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(loc.t('admin.settings.useGps')),
              ),
            ],
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final p in _results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                title: Text(p.name),
                subtitle: Text(p.region),
                onTap: _saving ? null : () => _apply(p),
              ),
          ],
          const Divider(height: 32),
          Text(loc.t('admin.settings.resolved'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _kv(loc.t('admin.settings.city'), site.cityName),
          _kv(loc.t('admin.settings.lat'), site.latitude.toStringAsFixed(4)),
          _kv(loc.t('admin.settings.lon'), site.longitude.toStringAsFixed(4)),
          _kv(loc.t('admin.settings.tz'), site.timezone),
          const Divider(height: 32),
          TextField(
            controller: _mapsKey,
            decoration: InputDecoration(
              labelText: loc.t('admin.settings.mapsKey'),
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            onChanged: (v) =>
                context.read<AppRepository>().setGoogleMapsApiKey(v),
          ),
          const SizedBox(height: 8),
          Text(loc.t('admin.settings.mapsHint'),
              style: const TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(color: AppColors.muted))),
          Expanded(
              child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
