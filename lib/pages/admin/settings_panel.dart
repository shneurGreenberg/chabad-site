import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/playful_icons.dart';

import '../../data/repository.dart';
import '../../models.dart';
import '../../state/auth.dart';
import '../../services/geo.dart';
import '../../services/location_zmanim.dart';
import '../../services/web_prefs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final _query = TextEditingController();
  final _mapsKey = TextEditingController();
  final _telegram = TextEditingController();
  final _vk = TextEditingController();
  final _youtube = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _website = TextEditingController();
  final _donateUrl = TextEditingController();
  final _bank = TextEditingController();
  final _whatsapp = TextEditingController();
  final _notify = TextEditingController();
  final _adminEmails = TextEditingController();
  final _editorPin = TextEditingController();
  final _import = TextEditingController();
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
    _telegram.text = repo.links.telegram;
    _vk.text = repo.links.vk;
    _youtube.text = repo.links.youtube;
    _facebook.text = repo.links.facebook;
    _instagram.text = repo.links.instagram;
    _website.text = repo.links.website;
    _donateUrl.text = repo.links.donateUrl;
    _bank.text = repo.links.bankDetails;
    _whatsapp.text = repo.links.whatsapp;
    _notify.text = repo.links.notifyChatId;
    _adminEmails.text = repo.links.adminEmails;
    _editorPin.text = AuthController.editorPin();
  }

  @override
  void dispose() {
    _query.dispose();
    _mapsKey.dispose();
    _telegram.dispose();
    _vk.dispose();
    _youtube.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _website.dispose();
    _donateUrl.dispose();
    _bank.dispose();
    _whatsapp.dispose();
    _notify.dispose();
    _adminEmails.dispose();
    _editorPin.dispose();
    _import.dispose();
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
        color: AppColors.card,
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
              style: TextStyle(color: AppColors.muted, height: 1.45)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(loc.t('admin.persist.note'),
                style: TextStyle(color: AppColors.muted, height: 1.45, fontSize: 13.5)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: loc.t('admin.settings.city'),
              prefixIcon: const PlayfulIcon(Icons.location_city_outlined),
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
                    : const PlayfulIcon(Icons.search, size: 18),
                label: Text(loc.t('admin.settings.search')),
              ).hoverLift(),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useGps,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const PlayfulIcon(Icons.my_location, size: 18),
                label: Text(loc.t('admin.settings.useGps')),
              ).hoverLift(),
            ],
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final p in _results)
              HoverScale(
                scale: 1.02,
                child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PlayfulIcon(Icons.place_outlined, color: AppColors.primary),
                title: Text(p.name),
                subtitle: Text(p.region),
                onTap: _saving ? null : () => _apply(p),
              ),
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
              prefixIcon: const PlayfulIcon(Icons.map_outlined),
            ),
            onChanged: (v) =>
                context.read<AppRepository>().setGoogleMapsApiKey(v),
          ),
          const SizedBox(height: 8),
          Text(loc.t('admin.settings.mapsHint'),
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
          const Divider(height: 32),
          Text(loc.t('admin.links'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _linkField(_telegram, loc.t('social.telegram'), Icons.telegram),
          _linkField(_vk, loc.t('social.vk'), Icons.group_outlined),
          _linkField(_youtube, loc.t('social.youtube'), Icons.smart_display_outlined),
          _linkField(_facebook, loc.t('social.facebook'), Icons.facebook),
          _linkField(
              _instagram, loc.t('social.instagram'), Icons.camera_alt_outlined),
          _linkField(_website, loc.t('social.website'), Icons.language),
          _linkField(
              _whatsapp, loc.t('social.whatsapp'), Icons.chat_outlined),
          _linkField(_donateUrl, loc.t('donate.url'), Icons.payments_outlined),
          TextField(
            controller: _bank,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: loc.t('donate.bank'),
              prefixIcon: const PlayfulIcon(Icons.account_balance_outlined),
            ),
            onChanged: (_) => _saveLinks(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notify,
            decoration: InputDecoration(
              labelText: loc.t('admin.notifyChat'),
              hintText: '123456789',
              prefixIcon: const PlayfulIcon(Icons.notifications_outlined),
            ),
            onChanged: (_) => _saveLinks(),
          ),
          const SizedBox(height: 8),
          Text(loc.t('admin.notifyChat.hint'),
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _adminEmails,
            decoration: InputDecoration(
              labelText: loc.t('admin.emails'),
              prefixIcon: const PlayfulIcon(Icons.admin_panel_settings_outlined),
            ),
            onChanged: (_) => _saveLinks(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _editorPin,
            obscureText: true,
            decoration: InputDecoration(
              labelText: loc.t('admin.editorPin'),
              prefixIcon: const PlayfulIcon(Icons.lock_outline),
            ),
            onChanged: (v) => AuthController.saveEditorPin(v),
          ),
          const SizedBox(height: 8),
          Text(loc.t('admin.editorPin.hint'),
              style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13)),
          const Divider(height: 32),
          Text(loc.t('admin.backup'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final json = context.read<AppRepository>().exportBackupJson();
                  downloadText(
                    'beit-menachem-backup.json',
                    json,
                  );
                },
                icon: const PlayfulIcon(Icons.download, size: 18),
                label: Text(loc.t('admin.backup.export')),
              ).hoverLift(),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _import,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.t('admin.backup.import'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final err = context
                  .read<AppRepository>()
                  .importBackupJson(_import.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err == null
                      ? loc.t('admin.settings.saved')
                      : loc.t('admin.backup.bad')),
                ),
              );
            },
            icon: const PlayfulIcon(Icons.upload, size: 18),
            label: Text(loc.t('admin.backup.apply')),
          ).hoverLift(),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _saveLinks() {
    final links = context.read<AppRepository>().links;
    links.telegram = _telegram.text.trim();
    links.vk = _vk.text.trim();
    links.youtube = _youtube.text.trim();
    links.facebook = _facebook.text.trim();
    links.instagram = _instagram.text.trim();
    links.website = _website.text.trim();
    links.donateUrl = _donateUrl.text.trim();
    links.bankDetails = _bank.text.trim();
    links.whatsapp = _whatsapp.text.trim();
    links.notifyChatId = _notify.text.trim();
    links.adminEmails = _adminEmails.text.trim();
    context.read<AppRepository>().refresh();
  }

  Widget _linkField(
    TextEditingController c,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: PlayfulIcon(icon),
        ),
        onChanged: (_) => _saveLinks(),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(k, style: TextStyle(color: AppColors.muted))),
          Expanded(
              child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
