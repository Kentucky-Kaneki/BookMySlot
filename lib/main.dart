import 'package:flutter/material.dart';
import 'login_screens/welcome_page.dart';

void main() => runApp(BMS());

class BMS extends StatelessWidget {
  const BMS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
      routes: {},
    );
  }
}
