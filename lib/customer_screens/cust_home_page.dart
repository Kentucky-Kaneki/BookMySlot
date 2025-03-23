import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  Future<void> logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello Abc!',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: kMainColor,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              weight: 10,
            ),
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
              await logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => WelcomePage()),
                (route) => false,
              );
            },
            tooltip: "Sign Out",
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gaming center Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.circle, color: Colors.green, size: 12),
                        SizedBox(width: 8),
                        Text(
                          'Open now    10am - 8pm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Location',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Games Available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text('.\n.\n.\n.'),
              const SizedBox(height: 24),
              const Text(
                'Notices',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text('There are no new notices available.'),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(300, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('Book Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
