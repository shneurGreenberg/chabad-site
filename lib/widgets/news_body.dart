import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/web_prefs.dart';
import '../theme.dart';

/// Renders news article body: plain text, optional `![alt](assets/...)` images,
/// and `https://` links.
class NewsBody extends StatelessWidget {
  const NewsBody({super.key, required this.text});
  final String text;

  static final _image = RegExp(r'!\[[^\]]*\]\((assets/[^)]+)\)');
  static final _url = RegExp(r'https://[^\s)\]]+');

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.ink,
      height: 1.6,
      fontSize: 16.5,
    );
    if (!_image.hasMatch(text)) {
      return SelectableText.rich(
        _linkify(text, style),
        style: style,
      );
    }
    final children = <Widget>[];
    var i = 0;
    for (final m in _image.allMatches(text)) {
      if (m.start > i) {
        final chunk = text.substring(i, m.start).trim();
        if (chunk.isNotEmpty) {
          children.add(SelectableText.rich(_linkify(chunk, style), style: style));
          children.add(const SizedBox(height: 12));
        }
      }
      final asset = m.group(1)!;
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
      children.add(const SizedBox(height: 16));
      i = m.end;
    }
    final tail = text.substring(i).trim();
    if (tail.isNotEmpty) {
      children.add(SelectableText.rich(_linkify(tail, style), style: style));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextSpan _linkify(String chunk, TextStyle style) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _url.allMatches(chunk)) {
      if (m.start > at) {
        spans.add(TextSpan(text: chunk.substring(at, m.start)));
      }
      final url = m.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: style.copyWith(
            color: AppColors.accent,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => openUrl(url),
        ),
      );
      at = m.end;
    }
    if (at < chunk.length) {
      spans.add(TextSpan(text: chunk.substring(at)));
    }
    return TextSpan(children: spans);
  }
}
