import 'package:flutter/material.dart';

class AdminUpdateEcpmScreen extends StatefulWidget {
  const AdminUpdateEcpmScreen({super.key});

  @override
  State<AdminUpdateEcpmScreen> createState() => _AdminUpdateEcpmScreenState();
}

class _AdminUpdateEcpmScreenState extends State<AdminUpdateEcpmScreen> {
  final TextEditingController _ecpmController = TextEditingController();
  double? _currentEcpm;
  String? _errorText;
  String? _statusText;

  @override
  void dispose() {
    _ecpmController.dispose();
    super.dispose();
  }

  void _handleUpdateEcpm() {
    final text = _ecpmController.text.trim();
    final ecpm = double.tryParse(text);

    if (ecpm == null || ecpm < 0) {
      setState(() {
        _errorText = 'Vui lòng nhập số hợp lệ (>= 0)';
        _statusText = null;
      });
      return;
    }

    // TODO: Replace with your backend/API logic here
    setState(() {
      _currentEcpm = ecpm;
      _errorText = null;
      _statusText = '✅ Đã cập nhật eCPM thành công!';
      _ecpmController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cập nhật eCPM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập giá trị eCPM mới:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ecpmController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'VD: 1.23',
                border: OutlineInputBorder(),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Cập nhật'),
                onPressed: _handleUpdateEcpm,
              ),
            ),
            const SizedBox(height: 24),
            if (_currentEcpm != null)
              Text(
                'eCPM hiện tại: ${_currentEcpm!.toStringAsFixed(2)} \$',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_statusText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _statusText!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
