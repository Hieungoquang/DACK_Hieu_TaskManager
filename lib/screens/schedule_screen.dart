import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Lập lịch thông minh")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            input("Giờ bắt đầu"),
            input("Giờ kết thúc"),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: Text("Tạo lịch tự động"),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(title: Text("Task $index"));
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget input(String hint) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}