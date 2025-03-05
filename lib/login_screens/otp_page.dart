import 'package:flutter/material.dart';
// import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OTPVerificationPage extends StatelessWidget {
  const OTPVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Confirm OTP code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'enter the OTP sent to the registered mobile number',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            // OtpTextField(
            //   numberOfFields: 6,
            //   borderColor: Colors.black,
            //   focusedBorderColor: Colors.black,
            //   cursorColor: Colors.black,
            //   showFieldAsBox: true,
            //   fieldWidth: 45,
            //   borderRadius: BorderRadius.circular(8),
            //   onCodeChanged: (String code) {},
            //   onSubmit: (String verificationCode) {},
            // ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: const Text('00:59',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  )),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(300, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {},
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
