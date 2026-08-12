import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class NewsletterSignup extends StatefulWidget {
  const NewsletterSignup({
    super.key,
    this.light = false,
    this.compact = false,
  });

  /// White-on-dark (footer) vs dark-on-light (home).
  final bool light;
  final bool compact;

  @override
  State<NewsletterSignup> createState() => _NewsletterSignupState();
}

class _NewsletterSignupState extends State<NewsletterSignup> {
  final _email = TextEditingController();
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = context.read<LocaleController>();
    final result =
        context.read<AppRepository>().subscribeNewsletter(_email.text);
    setState(() {
      switch (result) {
        case SubscribeResult.ok:
          _ok = true;
          _message = loc.t('newsletter.thanks');
          _email.clear();
        case SubscribeResult.invalid:
          _ok = false;
          _message = loc.t('common.emailInvalid');
        case SubscribeResult.duplicate:
          _ok = false;
          _message = loc.t('newsletter.duplicate');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.locWatch;
    final light = widget.light;
    final fg = light ? Colors.white : AppColors.ink;
    final hint = light
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.t('footer.newsletter'),
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: widget.compact ? 15 : 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loc.t('newsletter.hint'),
          style: TextStyle(color: hint, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: widget.compact ? 220 : 260,
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: light ? Colors.white : AppColors.ink),
                decoration: InputDecoration(
                  hintText: loc.t('common.email'),
                  hintStyle: TextStyle(color: hint),
                  filled: true,
                  fillColor: light
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  isDense: true,
                  prefixIcon: Icon(Icons.mail_outline,
                      size: 18, color: light ? Colors.white70 : AppColors.muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: light
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: light
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: light ? AppColors.accent : AppColors.primary,
                foregroundColor:
                    light ? AppColors.primaryDark : Colors.white,
              ),
              child: Text(loc.t('newsletter.join')),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: TextStyle(
              color: _ok
                  ? (light ? AppColors.accentSoft : const Color(0xFF0D9488))
                  : (light ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C)),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
