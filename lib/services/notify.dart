import '../models.dart';
import 'telegram.dart';

/// Admin alerts for new leads, orders, RSVPs and yahrzeit notes.
/// Telegram goes only to [notifyChatId] — never to the public channel.
class SiteNotify {
  static Future<void> send({
    required String notifyChatId,
    required String email,
    required String title,
    required String body,
  }) async {
    final chat = notifyChatId.trim();
    if (chat.isNotEmpty && TelegramService.instance.hasToken) {
      try {
        await TelegramService.instance.sendToChat(
          chatId: chat,
          text:
              '<b>${TelegramService.escapeHtml(title)}</b>\n$body\n\n${TelegramService.escapeHtml(email)}',
        );
        return;
      } catch (_) {}
    }
  }

  static Future<void> lead({
    required Lead lead,
    required String email,
    required String notifyChatId,
  }) {
    final topic = trLoc(lead.topic, 'he');
    return send(
      notifyChatId: notifyChatId,
      email: email,
      title: 'פנייה חדשה מהאתר',
      body: '${lead.name}\n${lead.phone}\n${lead.email}\n$topic',
    );
  }

  static Future<void> subscriber({
    required String subscriberEmail,
    required String email,
    required String notifyChatId,
  }) {
    return send(
      notifyChatId: notifyChatId,
      email: email,
      title: 'נרשם לניוזלטר',
      body: subscriberEmail,
    );
  }

  static Future<void> order({
    required StoreOrder order,
    required String email,
    required String notifyChatId,
  }) {
    final lines = [
      for (final l in order.lines) '${l.name} ×${l.qty}',
    ].join('\n');
    return send(
      notifyChatId: notifyChatId,
      email: email,
      title: 'הזמנה מהחנות הכשרה',
      body:
          '${order.name} · ${order.phone}\n${order.fulfillment}\n$lines\n\$${order.total.toStringAsFixed(0)}',
    );
  }

  static Future<void> rsvp({
    required CommunityEvent event,
    required EventRsvp rsvp,
    required String email,
    required String notifyChatId,
  }) {
    return send(
      notifyChatId: notifyChatId,
      email: email,
      title: 'הרשמה לאירוע: ${trLoc(event.title, 'he')}',
      body: '${rsvp.name} · ${rsvp.phone} · ${rsvp.guests}',
    );
  }
}
