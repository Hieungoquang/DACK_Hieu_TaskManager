import 'dart:convert';
import 'package:http/http.dart' as http;

class AiSuggestedTask {
  String title;
  String description;
  int priority; // 1: Low, 2: Medium, 3: High
  int duration; // minutes
  String category;
  bool isSelected;

  AiSuggestedTask({
    required this.title,
    required this.description,
    required this.priority,
    required this.duration,
    required this.category,
    this.isSelected = true,
  });
}

class AiService {
  // OPENROUTER API KEY - Replace with your own key
  static String get apiKey {
    const fromEnv = String.fromEnvironment('OPENROUTER_API_KEY');
    if (fromEnv.isNotEmpty && fromEnv != 'YOUR_API_KEY_HERE') {
      return fromEnv;
    }
    return 'YOUR_API_KEY_HERE';
  }

  // API URL
  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // AI GỢI Ý CÔNG VIỆC CHI TIẾT
  static Future<List<AiSuggestedTask>> generateSubtasks(
    String mainTaskTitle, {
    int count = 5,
  }) async {
    try {
      print("Đang gửi request tới OpenRouter để gợi ý $count việc con...");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'http://localhost',
          'X-Title': 'Task Manager',
        },
        body: jsonEncode({
          "model": "openai/gpt-3.5-turbo",
          "messages": [
            {
              "role": "user",
              "content": """
Bạn là AI trợ lý quản lý công việc và chia nhỏ lộ trình hành động.
Hãy phân tích mục tiêu của người dùng: "$mainTaskTitle"
Hãy chia nhỏ mục tiêu này thành đúng $count bước thực hiện cụ thể và thực tế.

Yêu cầu định dạng đầu ra:
Trả về chính xác $count dòng văn bản, mỗi dòng đại diện cho một tác vụ con theo định dạng phân tách bằng dấu gạch đứng (|) như sau:
[Tên tác vụ con] | [Thời lượng phút] | [Độ ưu tiên 1-3] | [Mô tả ngắn gọn]

Trong đó:
- Tên tác vụ con: Ngắn gọn, súc tích, dưới 8 từ, bắt đầu bằng động từ hành động.
- Thời lượng phút: Là một số nguyên (ví dụ: 30, 45, 60, 90, 120), ước tính thời gian thực hiện bước này.
- Độ ưu tiên: Số từ 1 đến 3 (1: Thấp, 2: Vừa, 3: Cao).
- Mô tả ngắn gọn: 1 câu mô tả hành động cụ thể cần làm.

Lưu ý quan trọng:
- Tuyệt đối không đánh số thứ tự dòng.
- Không kèm ký tự đặc biệt ở đầu dòng (như -, *, •).
- Không thêm bất kỳ văn bản chào hỏi, giải thích hay kết luận nào. Chỉ trả về đúng $count dòng định dạng trên.
"""
            }
          ]
        }),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text = data['choices'][0]['message']['content'].toString();

        final List<AiSuggestedTask> tasks = [];
        final lines = text.split('\n');

        for (var line in lines) {
          final cleanLine = line.trim();
          if (cleanLine.isEmpty) continue;

          final parts = cleanLine.split('|');
          if (parts.isNotEmpty) {
            // Lấy tiêu đề và làm sạch đầu dòng
            final title = parts[0].replaceAll(RegExp(r'^[-•*0-9.]+\s*'), '').trim();
            if (title.isEmpty) continue;

            int duration = 45;
            if (parts.length >= 2) {
              duration = int.tryParse(parts[1].trim()) ?? 45;
            }

            int priority = 2;
            if (parts.length >= 3) {
              priority = int.tryParse(parts[2].trim()) ?? 2;
              if (priority < 1 || priority > 3) priority = 2;
            }

            String desc = "Được gợi ý bởi AI";
            if (parts.length >= 4) {
              desc = parts[3].trim();
            }

            tasks.add(AiSuggestedTask(
              title: title,
              duration: duration,
              priority: priority,
              description: desc,
              category: 'Công việc',
            ));
          }
        }

        print("✅ ĐÃ PARSE THÀNH CÔNG ${tasks.length} TASKS.");
        return tasks;
      }

      return [];
    } catch (e) {
      print("❌ AI ERROR: $e");
      return [];
    }
  }
}
