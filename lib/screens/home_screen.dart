import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<String> tasks = List.generate(10, (index) => "Item $index");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 HEADER
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade100],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Xin chào", style: TextStyle(fontSize: 14)),
                    Text("Hiếu",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // 🔹 STATS
              Row(
                children: [
                  _buildStatCard("Hôm nay", "5"),
                  SizedBox(width: 10),
                  _buildStatCard("Hoàn thành", "3"),
                ],
              ),

              SizedBox(height: 12),

              // 🔹 SEARCH
              TextField(
                decoration: InputDecoration(
                  hintText: "Tìm kiếm...",
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              SizedBox(height: 12),

              // 🔹 FILTER TABS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab("Tất cả"),
                    _buildTab("Hôm nay"),
                    _buildTab("Quan trọng"),
                    _buildTab("Hoàn thành"),
                  ],
                ),
              ),

              SizedBox(height: 12),

              Text("Danh sách công việc",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(tasks[index]),
                        leading: Icon(Icons.check_circle_outline),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade100],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            SizedBox(height: 5),
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text),
      ),
    );
  }
}