import 'package:flutter/material.dart';
import 'ad_logs_screen.dart';
import 'daily_stack_screen.dart';
import 'withdrawal_history_screen.dart';
import 'admin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../session/user_session.dart';
import 'login_screen.dart';
import 'admin_list_user_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import '../main.dart';
import 'photo_list_screen.dart';


class Overview extends StatefulWidget
{
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview>
{
  final logger = Logger();
  // =======================
  // Khởi tạo
  // =======================

  @override
  void initState()
  {
    super.initState();
    _loadUserFromPrefs();

    WidgetsBinding.instance.addPostFrameCallback((_)
      {
        // Gọi hàm sau khi widget đã được xây dựng
      }
    );
  }

  // =======================
  // module
  // =======================
  Future<void> handleLogout(BuildContext context) async
  {
    final prefs = await SharedPreferences.getInstance();
    // Xóa toàn bộ dữ liệu trong SharedPreferences
    await prefs.clear(); 

    UserSession.userId = '';
    UserSession.email = '';
    UserSession.userName = '';
  }

  Future<void> signOut() async
  {
    try
    {
      // Đăng xuất khỏi Google Sign-In
      await GoogleSignIn().signOut();

      // Đăng xuất khỏi Firebase Authentication
      await FirebaseAuth.instance.signOut();

      // Xóa dữ liệu trong SharedPreferences và UserSession
      await handleLogout(context);

      // Hiển thị thông báo đăng xuất thành công
      if (mounted)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng xuất thành công'))
        );
        // Chờ 2 giây để người dùng thấy thông báo
        await Future.delayed(const Duration(seconds: 2));
        // Chuyển hướng về màn hình đăng nhập
        _navigateToLogin();
      }

      logger.i("Đăng xuất thành công");
    }
    catch (e)
    {
      logger.e("Lỗi khi đăng xuất: $e");

      if (mounted)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng xuất thất bại'))
        );
      }
    }
  }

  Future<void> _loadUserFromPrefs() async
  {
    final prefs = await SharedPreferences.getInstance();
    UserSession.userId = prefs.getString('userId');
    UserSession.email = prefs.getString('email');
    UserSession.userName = prefs.getString('userName');
  }

  void _navigateToLogin()
  {
    if (mounted)
    {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyApp())
      );
    }
    else
    {
      logger.w("Warning: Tried to navigate after widget was unmounted.");
    }
  }

  // =====================
  // Giao diện
  // =====================

  @override
  Widget build(BuildContext context)
  {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 41, 43, 66),
        appBar: AppBar(
          title: const Text(
            'TỔNG QUAN',
            style: TextStyle(
              fontWeight: FontWeight.bold, // In đậm
              color: Color.fromARGB(255, 255, 255, 255)
            )
          ),
          backgroundColor: const Color.fromARGB(255, 33, 35, 54),
          centerTitle: true,
          iconTheme: const IconThemeData(
            color: Colors.white // Đổi màu nút quay lại ở đây
          )
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
                    85
                  ) // Nền ô vuông tối đậm
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(
                        'assets/avatar.png'
                      ) // Hoặc dùng NetworkImage(...)
                    ),
                    SizedBox(height: 12),
                    Text(
                      UserSession.userName ?? 'Tên người dùng11',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      )
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ngày đăng ký: 01/01/2024',
                      style: TextStyle(color: Colors.grey)
                    )
                  ]
                )
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: ()
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminUpdateEcpmScreen()
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54
                  ) // Nền nút tối đậm
                ),
                child: const Text('Quản trị hệ thống')
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ()
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserListPage())
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54
                  ) // Nền nút tối đậm
                ),
                child: const Text('Quản lý người dùng')
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ()
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DailyTasksScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54
                  ) // Nền nút tối đậm
                ),
                child: const Text('Nhiệm vụ')
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ()
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdLogsScreen())
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54
                  ) // Nền nút tối đậm
                ),
                child: const Text('Thu nhập của tôi')
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ()
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawalHistoryScreen()
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(
                    255,
                    33,
                    35,
                    54
                  ) // Nền nút tối đậm
                ),
                child: const Text('Lịch sử rút tiền')
              ),

              const Spacer(),

              // Nút đăng xuất màu cam đậm, tách xa
              ElevatedButton(
                onPressed: ()
                {
                  showDialog(
                    context: context,
                    builder: (BuildContext context)
                    {
                      return AlertDialog(
                        title: const Text('Xác nhận đăng xuất'),
                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Hủy'),
                            onPressed: ()
                            {
                              Navigator.of(context).pop(); // Đóng dialog
                            }
                          ),
                          TextButton(
                            child: const Text(
                              'Đăng xuất',
                              style: TextStyle(color: Colors.red)
                            ),
                            onPressed: () async
                            {
                              Navigator.of(context).pop(); // Đóng dialog trước
                              await signOut(); // Gọi hàm đăng xuất
                            }
                          )
                        ]
                      );
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color.fromARGB(255, 33, 35, 54)
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white)
                )
              )
            ]
          )
        )
      )
    );
  }
}
