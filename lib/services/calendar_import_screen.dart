import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CalendarImportService {
  static Future<List<Map<String, dynamic>>> importICS() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
      );

      if (result == null) return [];

      String contents;

      if (kIsWeb) {
        // On web, use bytes
        final bytes = result.files.single.bytes;
        if (bytes == null) return [];
        contents = utf8.decode(bytes);
      } else {
        // On mobile/desktop, use path
        final file = File(result.files.single.path!);
        if (!await file.exists()) {
          throw Exception('File không tồn tại');
        }
        contents = await file.readAsString();
      }

      if (contents.isEmpty) {
        throw Exception('File trống');
      }

      final calendar = ICalendar.fromString(contents);

      List<Map<String, dynamic>> events = [];

      for (var event in calendar.data) {
        if (event['type'] == 'VEVENT') {
          final data = event['data'];

          // Parse start time with better handling
          DateTime? start;
          DateTime? end;

          if (data['dtstart'] != null) {
            final dtValue = data['dtstart'];
            if (dtValue is Map && dtValue['dt'] != null) {
              start = _parseICSDateTime(dtValue['dt']);
            } else if (dtValue is String) {
              start = _parseICSDateTime(dtValue);
            }
          }

          if (data['dtend'] != null) {
            final dtValue = data['dtend'];
            if (dtValue is Map && dtValue['dt'] != null) {
              end = _parseICSDateTime(dtValue['dt']);
            } else if (dtValue is String) {
              end = _parseICSDateTime(dtValue);
            }
          }

          // Skip events without valid dates
          if (start == null || end == null) continue;

          // Extract category/category from event
          String category = 'Công việc';
          if (data['categories'] != null) {
            final categories = data['categories'];
            if (categories is List && categories.isNotEmpty) {
              category = _mapCategory(categories.first.toString());
            } else if (categories is String) {
              category = _mapCategory(categories);
            }
          }

          // Extract priority from event
          int priority = 1;
          if (data['priority'] != null) {
            final prio = data['priority'];
            if (prio is int) {
              priority = prio.clamp(1, 3);
            } else if (prio is String) {
              final prioInt = int.tryParse(prio);
              if (prioInt != null) {
                priority = prioInt.clamp(1, 3);
              }
            }
          }

          events.add({
            'title': data['summary'] ?? 'Không có tiêu đề',
            'description': _cleanDescription(data['description'] ?? ''),
            'start': start,
            'end': end,
            'location': data['location'] ?? '',
            'category': category,
            'priority': priority,
            'isAllDay': _isAllDayEvent(start, end),
          });
        }
      }

      return events;
    } catch (e) {
      print('Lỗi import ICS: $e');
      return [];
    }
  }

  static DateTime? _parseICSDateTime(dynamic dtValue) {
    if (dtValue == null) return null;

    String dateStr = dtValue.toString();

    // Handle different ICS date formats
    // Format 1: 20240516T140000Z (UTC)
    // Format 2: 20240516T140000 (local)
    // Format 3: 20240516 (all day)

    try {
      // Try parsing as ISO string first
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return parsed;

      // Handle ICS format without separators
      if (dateStr.length >= 8) {
        String year = dateStr.substring(0, 4);
        String month = dateStr.substring(4, 6);
        String day = dateStr.substring(6, 8);

        String timeStr = '';
        if (dateStr.length >= 15 && dateStr[8] == 'T') {
          timeStr = dateStr.substring(9, 15);
        }

        String isoStr = '$year-$month-$day';
        if (timeStr.isNotEmpty) {
          isoStr +=
              'T${timeStr.substring(0, 2)}:${timeStr.substring(2, 4)}:${timeStr.substring(4, 6)}';

          // Handle timezone
          if (dateStr.endsWith('Z')) {
            isoStr += 'Z';
          }
        }

        return DateTime.tryParse(isoStr);
      }
    } catch (e) {
      print('Lỗi parse date: $e');
    }

    return null;
  }

  static String _cleanDescription(String description) {
    // Remove HTML tags if present
    String cleaned = description.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  static String _mapCategory(String category) {
    category = category.toLowerCase();
    if (category.contains('work') || category.contains('công việc')) {
      return 'Công việc';
    } else if (category.contains('personal') || category.contains('cá nhân')) {
      return 'Cá nhân';
    } else if (category.contains('study') || category.contains('học tập')) {
      return 'Học tập';
    } else {
      return 'Công việc';
    }
  }

  static bool _isAllDayEvent(DateTime start, DateTime end) {
    // If the event spans exactly 24 hours or more, it's likely an all-day event
    final duration = end.difference(start);
    return duration.inHours >= 24;
  }
}
