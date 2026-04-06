import 'package:flutter/material.dart';

class AddTaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thêm công việc")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            buildInput("Nhập tên công việc"),
            buildInput("Mô tả công việc"),
            buildInput("Chọn ngày"),
            buildInput("Ví dụ: 2 giờ"),

            DropdownButtonFormField(
              items: ["1", "2", "3"]
                  .map((e) => DropdownMenuItem(value: e, child: Text("Item $e")))
                  .toList(),
              onChanged: (value) {},
              decoration: InputDecoration(labelText: "Độ ưu tiên"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: Text("Lưu công việc"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInput(String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}