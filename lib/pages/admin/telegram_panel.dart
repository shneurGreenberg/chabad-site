import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../services/telegram.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/hover.dart';

class TelegramWizard extends StatefulWidget {
  const TelegramWizard({super.key});

  @override
  State<TelegramWizard> createState() => _TelegramWizardState();
}

class _TelegramWizardState extends State<TelegramWizard> {
  final _token = TextEditingController();
  final _channel = TextEditingController();
  final _tg = TelegramService.instance;
  bool _connecting = false;
  bool _pulling = false;
  String? _botLabel;

  @override
  void initState() {
    super.initState();
    _tg.loadSaved();
    _channel.text = _tg.channel.isEmpty ? '@jewishsib' : '@${_tg.channel}';
    if (_tg.hasToken) {
      _token.text = _tg.maskedToken;
      _botLabel = _tg.maskedToken;
    }
  }

  @override
  void dispose() {
    _token.dispose();
    _channel.dispose();
    super.dispose();
  }

  String _tokenValue() {
    final typed = _token.text.trim();
    if (typed.contains('…') && _tg.hasToken) return ''; // keep saved token
    return typed;
  }

  Future<void> _connect() async {
    final loc = context.loc;
    setState(() => _connecting = true);
    try {
      final info = await _tg.connect(
        token: _tokenValue(),
        channel: _channel.text,
      );
      if (!mounted) return;
      setState(() {
        _botLabel = info.username == null
            ? info.name
            : '${info.name} (@${info.username})';
        _token.text = _tg.maskedToken;
      });
      final repo = context.read<AppRepository>();
      repo.telegramBot
        ..enabled = true
        ..name = info.name
        ..handle = info.username == null ? '@bot' : '@${info.username}';
      repo.refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc.t('admin.tg.connected')}: ${info.name}'
            '${info.chatTitle == null ? '' : ' · ${info.chatTitle}'}',
          ),
        ),
      );
    } on TelegramException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_err(loc.t(e.messageKey), e.detail))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.tg.err.generic'))),
      );
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _pull() async {
    final loc = context.loc;
    final repo = context.read<AppRepository>();
    setState(() => _pulling = true);
    try {
      if (!_tg.hasToken) {
        await _connect();
      }
      final posts = await _tg.pullPosts();
      if (!mounted) return;
      final added = repo.importTelegramPosts(posts);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? loc.t('admin.tg.noPosts')
                : loc.t('admin.tg.imported').replaceAll('{n}', '$added'),
          ),
        ),
      );
    } on TelegramException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_err(loc.t(e.messageKey), e.detail))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.tg.err.generic'))),
      );
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  String _err(String msg, String? detail) {
    if (detail == null || detail.trim().isEmpty) return msg;
    return '$msg\n$detail';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final steps = <(IconData, String)>[
      (Icons.phone_iphone, loc.t('admin.tg.step1')),
      (Icons.search, loc.t('admin.tg.step2')),
      (Icons.smart_toy_outlined, loc.t('admin.tg.step3')),
      (Icons.content_copy, loc.t('admin.tg.step4')),
      (Icons.paste, loc.t('admin.tg.step5')),
      (Icons.campaign_outlined, loc.t('admin.tg.step6')),
      (Icons.alternate_email, loc.t('admin.tg.step7')),
      (Icons.verified_outlined, loc.t('admin.tg.step8')),
      (Icons.newspaper_outlined, loc.t('admin.tg.step9')),
    ];

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
          Row(children: [
            const CircleAvatar(
              backgroundColor: Color(0x1A0EA5E9),
              child: Icon(Icons.send, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.t('admin.bots.telegram'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  Text(loc.t('admin.tg.subtitle'),
                      style: TextStyle(
                          color: AppColors.muted, height: 1.4)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 22),
          Text(loc.t('admin.tg.guideTitle'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 10),
                  Icon(steps[i].$1, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(steps[i].$2,
                        style: const TextStyle(height: 1.4, fontSize: 15)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _token,
            obscureText: true,
            decoration: InputDecoration(
              labelText: loc.t('admin.tg.token'),
              prefixIcon: const Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _channel,
            decoration: InputDecoration(
              labelText: loc.t('admin.tg.channel'),
              hintText: '@jewishsib',
              prefixIcon: const Icon(Icons.campaign_outlined),
            ),
          ),
          if (_botLabel != null) ...[
            const SizedBox(height: 12),
            Text('${loc.t('admin.tg.connected')}: $_botLabel',
                style: const TextStyle(
                    color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _connecting ? null : _connect,
                icon: _connecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link, size: 18),
                label: Text(loc.t('admin.tg.connect')),
              ).hoverLift(),
              FilledButton.icon(
                onPressed: _pulling ? null : _pull,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9)),
                icon: _pulling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(loc.t('admin.tg.pull')),
              ).hoverLift(),
            ],
          ),
        ],
      ),
    );
  }
}
