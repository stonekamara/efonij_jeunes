import 'package:intl/intl.dart';

/// Formate une date en relatif (français), ex : « il y a 3 jours ».
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime.toLocal());

  if (diff.inSeconds < 60) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
  if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
  return formatDate(dateTime);
}

/// Formate une date en `jj/mm/aaaa` (ou `—` si nulle).
String formatDate(DateTime? dateTime) {
  if (dateTime == null) return '—';
  return DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
}
