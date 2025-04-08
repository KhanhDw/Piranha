import 'package:flutter/material.dart';
import 'ad_logs_screen.dart';
import 'daily_stack_screen.dart';
import 'withdrawal_history_screen.dart';
import 'admin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../session/user_session.dart';
import 'login_screen.dart';
import 'admin_list_user_screen.dart';

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  // =======================
  // module
  // =======================
  Future<void> handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('email');

    // Xóa thông tin trong session tạm thời
    UserSession.userId = null;
    UserSession.email = null;
  }

  // =====================
  // Giao diện
  // =====================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 41, 43, 66),
        appBar: AppBar(
          title: const Text(
            'TỔNG QUAN',
            style: TextStyle(
              fontWeight: FontWeight.bold, // In đậm
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 33, 35, 54),
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white, // Đổi màu nút quay lại ở đây
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Ô vuông chứa avatar, tên người dùng, ngày đăng ký
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color.fromARGB(
                    255,
                    54,
                    57,
                    85,
                  ), // Nền ô vuông tối đậm
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                        'assets/avatar.png',
                      ), // Hoặc dùng NetworkImage(...)
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tên người dùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ngày đăng ký: 01/01/2024',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUpdateEcpmScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text('Quản trị hệ thống'),
              ),

              const SizedBox(height: 12),

              // Các nút chức năng
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DailyTasksScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text('Nhiệm vụ'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdLogsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text('Thu nhập của tôi'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalHistoryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text('Lịch sử rút tiền'),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserListPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text('Quản lý người dùng'),
              ),

              const Spacer(),

              // Nút đăng xuất màu cam đậm, tách xa
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Hủy'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Đóng dialog
                            },
                          ),
                          TextButton(
                            child: const Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop(); // Đóng dialog trước
                              // Xử lý đăng xuất tại đây
                              handleLogout(context);
                              // chuyển hướng về logic screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },

                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54,
                  ), // Nền nút tối đậm
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
