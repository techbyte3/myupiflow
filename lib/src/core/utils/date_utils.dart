import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat _dayMonthYearTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  /// Format date as "25 Jan 2024"
  static String formatDate(DateTime date) => _dayMonthYear.format(date);

  /// Format date with time as "25 Jan 2024, 02:30 PM"
  static String formatDateTime(DateTime dateTime) => _dayMonthYearTime.format(dateTime);

  /// Format date as "Jan 2024"
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Format time as "02:30 PM"
  static String formatTime(DateTime dateTime) => _time.format(dateTime);

  /// Format date for API/database storage
  static String formatForStorage(DateTime date) => _iso.format(date);

  /// Get relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Get month name
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Parse ISO date string
  static DateTime parseIsoString(String isoString) {
    return DateTime.parse(isoString);
  }

  /// Get date range for filtering
  static DateTimeRange getDateRange(String period) {
    final now = DateTime.now();
    
    switch (period.toLowerCase()) {
      case 'today':
        return DateTimeRange(
          start: startOfDay(now),
          end: endOfDay(now),
        );
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: startOfDay(yesterday),
          end: endOfDay(yesterday),
        );
      case 'this week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: startOfDay(startOfWeek),
          end: endOfDay(now),
        );
      case 'this month':
        return DateTimeRange(
          start: startOfMonth(now),
          end: endOfMonth(now),
        );
      case 'last month':
        final lastMonth = DateTime(now.year, now.month - 1, now.day);
        return DateTimeRange(
          start: startOfMonth(lastMonth),
          end: endOfMonth(lastMonth),
        );
      case 'last 3 months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return DateTimeRange(
          start: startOfMonth(threeMonthsAgo),
          end: endOfDay(now),
        );
      case 'last 6 months':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return DateTimeRange(
          start: startOfMonth(sixMonthsAgo),
          end: endOfDay(now),
        );
      case 'this year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: endOfDay(now),
        );
      default:
        return DateTimeRange(
          start: startOfMonth(now),
          end: endOfMonth(now),
        );
    }
  }
}

extension DateTimeExtension on DateTime {
  String get formatted => AppDateUtils.formatDate(this);
  String get formattedWithTime => AppDateUtils.formatDateTime(this);
  String get relativeTime => AppDateUtils.getRelativeTime(this);
  bool get isToday => AppDateUtils.isToday(this);
  bool get isThisMonth => AppDateUtils.isThisMonth(this);
}