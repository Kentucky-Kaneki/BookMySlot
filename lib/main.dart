import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screens/welcome_page.dart';
import 'package:book_my_slot/customer_screens/cust_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gumklurwkhereimycevd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1bWtsdXJ3a2hlcmVpbXljZXZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0ODQwNzAsImV4cCI6MjA1ODA2MDA3MH0.uJ-N0x_k3zY-Var5ONawnGYUbZgOS8k1W3Rl_rhQheE',
  );

  String? token = await getUserSession();
  runApp(BMS(isLoggedIn: token != null));
}

Future<String?> getUserSession() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token'); // Retrieve saved token
}

class BMS extends StatelessWidget {
  final bool isLoggedIn;

  const BMS({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const CustomerHomePage() : const WelcomePage(),
    );
  }
}
