import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  // Cấu hình EmailJS (Bạn cần thay thế bằng thông tin tài khoản của mình)
  static const String _serviceId = 'service_yhojs5e';
  static const String _templateIdInvite =
      'template_czdqage'; // Template ID cho lời mời
  static const String _templateIdAssign =
      'template_lesu5pk'; // Template ID cho giao việc
  static const String _userId =
      '0d9tSMGXY_uLXiGoB'; // Thay bằng Public Key của bạn

  static Future<bool> sendProjectInvitation({
    required String recipientEmail,
    required String projectName,
    required String inviterName,
    required String inviteLink,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      debugPrint('=== BẮT ĐẦU GỬI EMAIL MỜI ===');
      debugPrint('Đến: $recipientEmail');
      debugPrint('Dự án: $projectName');
      debugPrint('Người mời: $inviterName');
      debugPrint('Link: $inviteLink');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateIdInvite,
          'user_id': _userId,
          'template_params': {
            'to_email': recipientEmail,
            'project_name': projectName,
            'inviter_name': inviterName,
            'invite_link': inviteLink,
            'message':
                'Bạn đã được mời tham gia vào dự án $projectName bởi $inviterName. Nhấn vào liên kết để tham gia: $inviteLink',
          },
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Email mời tham gia đã được gửi đến $recipientEmail');
        return true;
      } else {
        debugPrint('❌ Lỗi gửi email: ${response.body}');
        debugPrint('❌ Status Code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌❌ Lỗi kết nối khi gửi email: $e');
      debugPrint('❌❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  static Future<bool> sendTaskAssignment({
    required String recipientEmail,
    required String taskTitle,
    required String projectName,
    required String assignerName,
    String? taskDescription,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      debugPrint('=== BẮT ĐẦU GỬI EMAIL GIAO VIỆC ===');
      debugPrint('Đến: $recipientEmail');
      debugPrint('Task: $taskTitle');
      debugPrint('Dự án: $projectName');
      debugPrint('Người giao: $assignerName');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateIdAssign,
          'user_id': _userId,
          'template_params': {
            'to_email': recipientEmail,
            'task_title': taskTitle,
            'project_name': projectName,
            'assigner_name': assignerName,
            'task_description': taskDescription ?? '',
            'message':
                'Bạn đã được giao nhiệm vụ "$taskTitle" trong dự án "$projectName" bởi $assignerName.${taskDescription != null && taskDescription.trim().isNotEmpty ? ' Mô tả: $taskDescription' : ''}',
          },
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Email giao việc đã được gửi đến $recipientEmail');
        return true;
      } else {
        debugPrint('❌ Lỗi gửi email: ${response.body}');
        debugPrint('❌ Status Code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌❌ Lỗi kết nối khi gửi email: $e');
      debugPrint('❌❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  static String buildProjectInvitationLink({
    required String projectId,
    required String inviteeId,
  }) {
    final base = Uri.base;
    final origin = base.hasScheme && base.host.isNotEmpty
        ? '${base.scheme}://${base.authority}'
        : 'https://taskflow.app';
    return '$origin/#/project-invite?projectId=$projectId&inviteeId=$inviteeId';
  }
}
