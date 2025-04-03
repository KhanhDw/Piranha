import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdLogsScreen extends StatefulWidget {
  const AdLogsScreen({super.key});

  @override
  _AdLogsScreenState createState() => _AdLogsScreenState();
}

class _AdLogsScreenState extends State<AdLogsScreen> {
  final Future<List<Map<String, dynamic>>> _adLogsFuture = getAdLogs();

  static Future<List<Map<String, dynamic>>> getAdLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getStringList('ad_logs') ?? [];
    return log.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ad Logs'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _adLogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final adLogs = snapshot.data!;
            if (adLogs.isEmpty) {
              return Center(child: Text('No ad logs found.'));
            } else {
              return ListView.builder(
                itemCount: adLogs.length,
                itemBuilder: (context, index) {
                  final log = adLogs[index];
                  return ListTile(
                    title: Text('User ID: ${log['userId']}'),
                    subtitle: Text('Timestamp: ${log['timestamp']}'),
                  );
                },
              );
            }
          } else {
            return Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}