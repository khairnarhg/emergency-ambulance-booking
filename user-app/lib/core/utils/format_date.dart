import 'package:intl/intl.dart';

String formatDateTime(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return isoString;
  }
}

String formatDate(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('dd MMM yyyy').format(dt);
  } catch (_) {
    return isoString;
  }
}

String formatTime(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dt);
  } catch (_) {
    return isoString;
  }
}

String timeAgo(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(isoString);
  } catch (_) {
    return isoString;
  }
}
