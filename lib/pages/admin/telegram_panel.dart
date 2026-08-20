import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models.dart';
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
  bool _publishing = false;
  String? _publishingId;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await _tg.loadSavedAsync();
    if (!mounted) return;
    setState(() {
      _channel.text = _tg.channel.isEmpty ? '@jewishsib' : '@${_tg.channel}';
      if (_tg.hasToken) {
        _token.text = _tg.maskedToken;
      }
    });
  }

  @override
  void dispose() {
    _token.dispose();
    _channel.dispose();
    super.dispose();
  }

  String _tokenValue() {
    final typed = _token.text.trim();
    if (typed.contains('…') && _tg.hasToken) return '';
    return typed;
  }

  String? _connectedLabel() {
    if (!_tg.isConnected) return null;
    if (_tg.botName.isEmpty && _tg.botUsername.isEmpty) {
      return _tg.maskedToken;
    }
    final user = _tg.botUsername.isEmpty ? '' : ' (@${_tg.botUsername})';
    return '${_tg.botName}$user';
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
      setState(() => _token.text = _tg.maskedToken);
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

  Future<void> _publishOne(NewsArticle a) async {
    final loc = context.loc;
    final repo = context.read<AppRepository>();
    setState(() => _publishingId = a.id);
    try {
      await repo.publishNewsToTelegram(a, loc.lang);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.tg.publishedOne'))),
      );
    } on TelegramException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_err(loc.t(e.messageKey), e.detail))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('admin.tg.err.publish'))),
      );
    } finally {
      if (mounted) setState(() => _publishingId = null);
    }
  }

  Future<void> _publishPending() async {
    final loc = context.loc;
    final repo = context.read<AppRepository>();
    setState(() => _publishing = true);
    try {
      if (!_tg.hasToken) await _connect();
      final n = await repo.publishPendingNewsToTelegram(loc.lang);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            n == 0
                ? loc.t('admin.tg.nonePending')
                : loc.t('admin.tg.publishedN').replaceAll('{n}', '$n'),
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
        SnackBar(content: Text(loc.t('admin.tg.err.publish'))),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _err(String msg, String? detail) {
    if (detail == null || detail.trim().isEmpty) return msg;
    return '$msg\n$detail';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final repo = context.watch<AppRepository>();
    final connected = _connectedLabel();
    final pending = repo.newsPendingTelegram;
    final posted = repo.news.where((a) => a.onTelegram).toList();
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
                      style: TextStyle(color: AppColors.muted, height: 1.4)),
                ],
              ),
            ),
          ]),
          if (connected != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6EE7B7)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${loc.t('admin.tg.connected')}: $connected'
                    '${_tg.channel.isEmpty ? '' : ' · @${_tg.channel}'}',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(loc.t('admin.tg.guideTitle'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              children: [
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(steps[i].$2,
                              style: const TextStyle(height: 1.35, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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
              FilledButton.icon(
                onPressed: _publishing || pending.isEmpty ? null : _publishPending,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669)),
                icon: _publishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload, size: 18),
                label: Text(loc.t('admin.tg.publishAll')),
              ).hoverLift(),
            ],
          ),
          const SizedBox(height: 22),
          Text(loc.t('admin.tg.queueTitle'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            loc
                .t('admin.tg.queueHint')
                .replaceAll('{pending}', '${pending.length}')
                .replaceAll('{posted}', '${posted.length}'),
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          for (final a in repo.news.take(16))
            _NewsTelegramRow(
              article: a,
              busy: _publishingId == a.id,
              onPublish: () => _publishOne(a),
            ),
        ],
      ),
    );
  }
}

class _NewsTelegramRow extends StatelessWidget {
  const _NewsTelegramRow({
    required this.article,
    required this.busy,
    required this.onPublish,
  });
  final NewsArticle article;
  final bool busy;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final done = article.onTelegram;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        done ? Icons.check_circle : Icons.schedule,
        color: done ? const Color(0xFF059669) : const Color(0xFFD97706),
      ),
      title: Text(
        trLoc(article.title, loc.lang),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        done
            ? loc.t('admin.tg.statusPosted') +
                (article.telegramPublishedAt == null
                    ? ''
                    : ' · ${DateFormat.MMMd(loc.lang).add_Hm().format(article.telegramPublishedAt!)}')
            : loc.t('admin.tg.statusPending'),
        style: TextStyle(
          color: done ? const Color(0xFF059669) : const Color(0xFFD97706),
          fontSize: 12.5,
        ),
      ),
      trailing: done
          ? null
          : TextButton(
              onPressed: busy ? null : onPublish,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.t('admin.tg.publishOne')),
            ),
    );
  }
}
