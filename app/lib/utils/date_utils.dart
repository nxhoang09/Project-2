import 'package:intl/intl.dart';

class MyDateUtils {
  static DateTime? _parseToLocal(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(normalized);
    final safeValue = hasTimezone ? normalized : '${normalized}Z';

    try {
      return DateTime.parse(safeValue).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String formatTime(String? utcString) {
    final localDate = _parseToLocal(utcString);
    if (localDate == null) return '--:--';
    return DateFormat('HH:mm').format(localDate);
  }

  static bool isSameDay(String? dateString1, String? dateString2) {
    final d1 = _parseToLocal(dateString1);
    final d2 = _parseToLocal(dateString2);
    if (d1 == null || d2 == null) return false;
    
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  static String getDateHeader(String? utcString) {
    final date = _parseToLocal(utcString);
    if (date == null) return 'KHÔNG RÕ NGÀY';

    DateTime now = DateTime.now();

    DateTime dateOnly = DateTime(date.year, date.month, date.day);
    DateTime todayOnly = DateTime(now.year, now.month, now.day);
    DateTime yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

    String dayMonth = DateFormat('dd/MM').format(date); // Định dạng 20/10

    if (dateOnly.isAtSameMomentAs(todayOnly)) {
      return 'HÔM NAY - $dayMonth';
    } else if (dateOnly.isAtSameMomentAs(yesterdayOnly)) {
      return 'HÔM QUA - $dayMonth';
    } else {
      // Nếu là ngày cũ hơn nữa thì hiện full ngày tháng năm
      return DateFormat('dd/MM/yyyy').format(date); 
    }
  }
}