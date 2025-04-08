import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  _DailyTasksScreenState createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  List<Map<String, dynamic>> dailyTasks = [];
  static const List<Map<String, dynamic>> allTasks = [
    {'title': 'Chọn thích 10 ảnh', 'progress': 0, 'goal': 10},
    {'title': 'Mở khóa 3 ảnh VIP', 'progress': 0, 'goal': 3},
    {
      'title': 'Tìm thấy 10 quảng cáo khi lướt ảnh tại trang chủ',
      'progress': 0,
      'goal': 10,
    },
    {'title': 'Tải 3 ảnh', 'progress': 0, 'goal': 3},
    {'title': 'Xem 15 ảnh, mỗi ảnh 20s', 'progress': 0, 'goal': 15},
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyTasks();
  }

  Future<void> _loadDailyTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastDate = prefs.getString('last_task_date');
    final String today = DateTime.now().toString().substring(
      0,
      10,
    ); // Lấy ngày YYYY-MM-DD

    if (lastDate != today) {
      // Nếu là ngày mới, random 5 nhiệm vụ
      await _generateDailyTasks(prefs, today);
    } else {
      // Nếu là cùng ngày, lấy nhiệm vụ đã lưu
      final String? tasksJson = prefs.getString('daily_tasks');
      if (tasksJson != null) {
        setState(() {
          dailyTasks = List<Map<String, dynamic>>.from(jsonDecode(tasksJson));
        });
      }
    }
  }

  Future<void> _generateDailyTasks(
    SharedPreferences prefs,
    String today,
  ) async {
    final random = Random();
    final List<Map<String, dynamic>> shuffledTasks = List.from(allTasks)
      ..shuffle(random);
    final List<Map<String, dynamic>> selectedTasks =
        shuffledTasks.take(5).map((task) {
          return Map<String, dynamic>.from(
            task,
          ); // Sao chép để không thay đổi allTasks
        }).toList();

    setState(() {
      dailyTasks = selectedTasks;
    });

    // Lưu nhiệm vụ và ngày vào SharedPreferences
    await prefs.setString('daily_tasks', jsonEncode(dailyTasks));
    await prefs.setString('last_task_date', today);
  }

  Future<void> _updateTaskProgress(int index, int newProgress) async {
    setState(() {
      dailyTasks[index]['progress'] = newProgress;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_tasks', jsonEncode(dailyTasks));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Nhiệm vụ hàng ngày',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            dailyTasks.isEmpty
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : ListView.builder(
                  itemCount: dailyTasks.length,
                  itemBuilder: (context, index) {
                    final task = dailyTasks[index];
                    final progress = task['progress'] as int;
                    final goal = task['goal'] as int;
                    final isCompleted = progress >= goal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tiến độ: $progress/${task['goal']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                isCompleted
                                    ? null
                                    : () {
                                      _updateTaskProgress(
                                        index,
                                        progress + 1,
                                      ); // Tăng tiến độ
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isCompleted
                                      ? Colors.grey
                                      : const Color(0xFF5E5E5E),
                            ),
                            child: Text(
                              isCompleted ? 'Hoàn thành' : 'Thực hiện',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
