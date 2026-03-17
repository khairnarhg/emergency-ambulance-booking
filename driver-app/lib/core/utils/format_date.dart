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

String formatTime(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('hh:mm a').format(dt);
  } catch (_) {
    return isoString;
  }
}

String formatDateShort(String? isoString) {
  if (isoString == null) return '—';
  try {
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('dd MMM').format(dt);
  } catch (_) {
    return isoString;
  }
}

String timeAgo(String? isoString) {
  if (isoString == null) return '';
  try {
    final dt = DateTime.parse(isoString);
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) {
    return '';
  }
}

String durationString(String? start, String? end) {
  if (start == null || end == null) return '—';
  try {
    final s = DateTime.parse(start);
    final e = DateTime.parse(end);
    final diff = e.difference(s);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  } catch (_) {
    return '—';
  }
}
