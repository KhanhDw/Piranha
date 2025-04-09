import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdLogsScreen extends StatefulWidget {
  const AdLogsScreen({super.key});

  @override
  _AdLogsScreenState createState() => _AdLogsScreenState();

  static Future<void> logAdImpression(String screenName) async {
    final prefs = await SharedPreferences.getInstance();
    final existingLogsString = prefs.getString('ad_impression_logs');
    List<Map<String, dynamic>> existingLogs = [];

    if (existingLogsString != null) {
      existingLogs =
          (jsonDecode(existingLogsString) as List<dynamic>)
              .cast<Map<String, dynamic>>();
    }

    bool found = false;
    for (var log in existingLogs) {
      if (log.containsKey(screenName)) {
        log[screenName] = (log[screenName] as int) + 1;
        found = true;
        break;
      }
    }

    if (!found) {
      existingLogs.add({screenName: 1});
    }

    await prefs.setString('ad_impression_logs', jsonEncode(existingLogs));
  }

  static Future<List<Map<String, dynamic>>> getAdImpressionLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('ad_impression_logs');
    if (logsString != null) {
      return (jsonDecode(logsString) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    return [];
  }
}

class _AdLogsScreenState extends State<AdLogsScreen> {
  final Future<List<Map<String, dynamic>>> _adImpressionLogsFuture =
      AdLogsScreen.getAdImpressionLogs();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '25,653 đ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Đổi màu nút quay lại ở đây
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'eCPM:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '1,00 US \$',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Lượt hiển thị quảng cáo',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adImpressionLogsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text(
                          'Lỗi: ${snapshot.error}',
                          style: TextStyle(color: Colors.white),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                          'Chưa có lượt hiển thị nào',
                          style: TextStyle(color: Colors.white70),
                        );
                      } else {
                        final logs = snapshot.data!;
                        int total = 0;

                        final rows =
                            logs.map((log) {
                              final screenName = log.keys.first;
                              final count = log.values.first;
                              total += count as int;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$screenName:',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${count} lượt',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList();

                        return Column(
                          children: [
                            // Các hàng từ logs
                            ...rows,
                            // Dòng phân cách
                            const Divider(color: Colors.white24, height: 24),
                            // Tổng lượt hiển thị
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tổng lượt hiển thị',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$total lượt',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );

                        // return Column(children: rows);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Công thức tính doanh thu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E5E5E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'eCPM × Lượt hiển thị',
                          style: TextStyle(color: Colors.white),
                        ),
                        Divider(color: Colors.white),
                        Text('1000', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '= Doanh thu',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Doanh thu:   1,03 \$ × 25,000 đ = 25,213 đ',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Thông báo: eCPM không cố định, giá trị này phụ thuộc vào đơn vị cung cấp quảng cáo.\n\n'
                'Chúng tôi sẽ thanh toán mỗi tháng 1 lần vào ngày thứ 5 tuần đầu tiên của tháng. Doanh thu của phải từ 1 USD trở lên',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                softWrap: true,
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ví dụ cách bạn có thể gọi logAdImpression từ nơi khác trong ứng dụng của bạn:
// AdLogsScreen.logAdImpression('main screen');
// AdLogsScreen.logAdImpression('product detail screen');
// AdLogsScreen.logAdImpression('main screen');
