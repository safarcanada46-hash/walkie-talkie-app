import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatelessWidget {
  final String usdtAddress = 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuW9'; // example USDT address

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('USDT Payment'),
        backgroundColor: Colors.grey[900],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scan to Pay with USDT',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 20),
            ),
            SizedBox(height: 20),
            QrImageView(
              data: 'usdt:$usdtAddress',
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Address: $usdtAddress',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}