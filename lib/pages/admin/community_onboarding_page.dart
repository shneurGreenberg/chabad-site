import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../widgets/common.dart';
import '../../services/tenant_cloud.dart';
import '../../services/web_prefs.dart';
import '../../state/auth.dart';
import '../../tenant/tenant_registry.dart';
import '../../tenant/tenant_slug.dart';
import '../../tenant/tenant_seed.dart';
import '../../theme.dart';
import 'admin.dart';

class CommunityOnboardingPage extends StatelessWidget {
  const CommunityOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isLoggedIn) return const AdminLogin();
    return const _OnboardingForm();
  }
}

class _OnboardingForm extends StatefulWidget {
  const _OnboardingForm();

  @override
  State<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<_OnboardingForm> {
  final _nameHe = TextEditingController();
  final _nameEn = TextEditingController();
  final _nameRu = TextEditingController();
  final _cityHe = TextEditingController();
  final _cityEn = TextEditingController();
  final _cityRu = TextEditingController();
  final _slug = TextEditingController();
  final _primary = TextEditingController(text: '#132A5C');
  final _accent = TextEditingController(text: '#C9A227');
  final _addressHe = TextEditingController();
  final _addressEn = TextEditingController();
  final _addressRu = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _adminEmail = TextEditingController();
  final _aboutHe = TextEditingController();
  final _aboutEn = TextEditingController();
  final _aboutRu = TextEditingController();
  final _sourceCredit = TextEditingController();

  bool _langHe = true;
  bool _langRu = true;
  bool _langEn = true;
  String? _logoName;
  Uint8List? _logoBytes;
  final _photos = <String, Uint8List>{};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameHe.dispose();
    _nameEn.dispose();
    _nameRu.dispose();
    _cityHe.dispose();
    _cityEn.dispose();
    _cityRu.dispose();
    _slug.dispose();
    _primary.dispose();
    _accent.dispose();
    _addressHe.dispose();
    _addressEn.dispose();
    _addressRu.dispose();
    _phone.dispose();
    _email.dispose();
    _adminEmail.dispose();
    _aboutHe.dispose();
    _aboutEn.dispose();
    _aboutRu.dispose();
    _sourceCredit.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _logoName = file.name;
    _logoBytes = bytes;
    setState(() {});
  }

  Future<void> _pickPhotos() async {
    final files = await ImagePicker().pickMultiImage();
    for (final f in files) {
      _photos[f.name] = await f.readAsBytes();
    }
    setState(() {});
  }

  Map<String, dynamic> _buildJson(String id) {
    final langs = <String>[
      if (_langHe) 'he',
      if (_langRu) 'ru',
      if (_langEn) 'en',
    ];
    return {
      'id': id,
      'name': {'he': _nameHe.text, 'en': _nameEn.text, 'ru': _nameRu.text},
      'city': {'he': _cityHe.text, 'en': _cityEn.text, 'ru': _cityRu.text},
      'address': {
        'he': _addressHe.text,
        'en': _addressEn.text,
        'ru': _addressRu.text,
      },
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'about': {
        'he': _aboutHe.text,
        'en': _aboutEn.text,
        'ru': _aboutRu.text,
      },
      'languages': langs,
      'adminEmail': _adminEmail.text.trim(),
      'colors': {'primary': _primary.text.trim(), 'accent': _accent.text.trim()},
      'logo': _logoName ?? '',
      'photos': _photos.keys.toList(),
      'sourceCredit': _sourceCredit.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = _slug.text.trim().toLowerCase();
    final slugErr = await validateTenantSlug(id);
    if (slugErr != null) {
      setState(() {
        _busy = false;
        _error = slugErr;
      });
      return;
    }
    final images = <String, Uint8List>{..._photos};
    if (_logoName != null && _logoBytes != null) {
      images[_logoName!] = _logoBytes!;
    }
    final pkg = TenantSeedPackage(
      id: id,
      json: _buildJson(id),
      imageFiles: images,
    );
    String? cloudErr;
    if (TenantCloudService.instance.canWrite) {
      cloudErr = await TenantCloudService.instance.saveTenantPackage(pkg);
    }
    if (cloudErr != null && TenantCloudService.instance.canWrite) {
      setState(() {
        _busy = false;
        _error = cloudErr;
      });
      return;
    }
    await TenantRegistry.instance.save(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    final loc = context.read<LocaleController>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('admin.communities.saved'))),
    );
  }

  void _downloadPackage() {
    final id = _slug.text.trim().toLowerCase();
    if (id.isEmpty) return;
    final images = <String, Uint8List>{..._photos};
    if (_logoName != null && _logoBytes != null) {
      images[_logoName!] = _logoBytes!;
    }
    final pkg = TenantSeedPackage(
      id: id,
      json: _buildJson(id),
      imageFiles: images,
    );
    downloadText(
      '$id-tenant-package.json',
      const JsonEncoder.withIndent('  ').convert(pkg.toExportJson()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(loc.t('admin.communities.onboarding.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/communities'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.t('admin.communities.onboarding.subtitle'),
                  style: TextStyle(color: AppColors.muted, height: 1.45)),
              const SizedBox(height: 20),
              _section(loc.t('admin.communities.field.name')),
              _locFields(_nameHe, _nameEn, _nameRu),
              _section(loc.t('admin.communities.field.city')),
              _locFields(_cityHe, _cityEn, _cityRu),
              TextField(
                controller: _slug,
                decoration: InputDecoration(
                  labelText: loc.t('admin.communities.field.slug'),
                  helperText: loc.t('admin.communities.field.slugHint'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _primary,
                      decoration: InputDecoration(
                        labelText: loc.t('admin.communities.field.primary'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _accent,
                      decoration: InputDecoration(
                        labelText: loc.t('admin.communities.field.accent'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickLogo,
                icon: const Icon(Icons.image_outlined),
                label: Text(loc.t('admin.communities.field.logo')),
              ),
              if (_logoName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_logoName!, style: TextStyle(color: AppColors.muted)),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(loc.t('admin.communities.field.photos')),
              ),
              _section(loc.t('admin.communities.field.contact')),
              _locFields(_addressHe, _addressEn, _addressRu, labels: true),
              TextField(
                controller: _phone,
                decoration: InputDecoration(
                  labelText: loc.t('admin.communities.field.phone'),
                ),
              ),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: loc.t('admin.communities.field.email'),
                ),
              ),
              TextField(
                controller: _adminEmail,
                decoration: InputDecoration(
                  labelText: loc.t('admin.communities.field.adminEmail'),
                ),
              ),
              _section(loc.t('admin.communities.field.languages')),
              Wrap(
                spacing: 12,
                children: [
                  FilterChip(
                    label: const Text('עברית'),
                    selected: _langHe,
                    onSelected: (v) => setState(() => _langHe = v),
                  ),
                  FilterChip(
                    label: const Text('Русский'),
                    selected: _langRu,
                    onSelected: (v) => setState(() => _langRu = v),
                  ),
                  FilterChip(
                    label: const Text('English'),
                    selected: _langEn,
                    onSelected: (v) => setState(() => _langEn = v),
                  ),
                ],
              ),
              _section(loc.t('admin.communities.field.about')),
              _locFields(_aboutHe, _aboutEn, _aboutRu, multiline: true),
              TextField(
                controller: _sourceCredit,
                decoration: InputDecoration(
                  labelText: loc.t('admin.communities.field.sourceCredit'),
                ),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.t('admin.communities.onboarding.submit')),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _downloadPackage,
                child: Text(loc.t('admin.communities.downloadPackage')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _locFields(
    TextEditingController he,
    TextEditingController en,
    TextEditingController ru, {
    bool labels = false,
    bool multiline = false,
  }) {
    return Column(
      children: [
        TextField(
          controller: he,
          decoration: InputDecoration(labelText: labels ? 'עברית' : 'שם HE'),
          maxLines: multiline ? 4 : 1,
        ),
        TextField(
          controller: en,
          decoration: InputDecoration(labelText: labels ? 'English' : 'Name EN'),
          maxLines: multiline ? 4 : 1,
        ),
        TextField(
          controller: ru,
          decoration: InputDecoration(labelText: labels ? 'Русский' : 'Имя RU'),
          maxLines: multiline ? 4 : 1,
        ),
      ],
    );
  }
}
