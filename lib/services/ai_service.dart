import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  //OPENROUTER API KEY - Replace with your own key
  static const String apiKey = String.fromEnvironment('OPENROUTER_API_KEY',
      defaultValue: 'YOUR_API_KEY_HERE');

  // API URL
  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // AI GỢI Ý CÔNG VIỆC
  static Future<List<String>> generateSubtasks(String mainTaskTitle) async {
    try {
      print("Đang gửi request tới OpenRouter...");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          // 🔹 AUTH
          'Authorization': 'Bearer $apiKey',

          // 🔹 JSON
          'Content-Type': 'application/json',

          // 🔹 QUAN TRỌNG CHO WEB
          'HTTP-Referer': 'http://localhost',
          'X-Title': 'Task Manager',
        },
        body: jsonEncode({
          // 🔹 MODEL
          "model": "openai/gpt-3.5-turbo",

          "messages": [
            {
              "role": "user",
              "content": """
Bạn là AI quản lý công việc.

Người dùng nhập:
"$mainTaskTitle"

Hãy chia nhỏ công việc này thành 3 đến 5 công việc con.

Yêu cầu:
- mỗi dòng 1 task
- không đánh số
- ngắn gọn
- dễ hiểu
"""
            }
          ]
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      // SUCCESS
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String text = data['choices'][0]['message']['content'].toString();

        // CLEAN TASKS
        final List<String> tasks = text
            .split('\n')
            .map((e) {
              return e
                  .replaceAll(
                    RegExp(r'^[-•*0-9.]+\s*'),
                    '',
                  )
                  .trim();
            })
            .where((e) => e.isNotEmpty)
            .toList();

        print("✅ TASKS: $tasks");

        return tasks;
      }

      return [];
    } catch (e) {
      print("❌ AI ERROR: $e");

      return [];
    }
  }
}
