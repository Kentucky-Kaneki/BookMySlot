import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/constants.dart';
import 'center_details_page.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'cust_profile_page.dart';
import 'your_bookings.dart';

class CenterSearchPage extends StatefulWidget {
  const CenterSearchPage({super.key});

  @override
  _CenterSearchPageState createState() => _CenterSearchPageState();
}

class _CenterSearchPageState extends State<CenterSearchPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> gamingCenters = [];
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGamingCenters();
  }

  Future<void> logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const CenterSearchPage();
        break;
      case 1:
        nextPage = const YourBookings();
        break;
      case 2:
        nextPage = const CustomerProfilePage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _loadGamingCenters() async {
    setState(() {
      _isLoading = true;
    });

    final response = await supabase.from('game_center').select('id, name');

    setState(() {
      gamingCenters = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Find Game Center',
            style: kAppBarTextStyle2,
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
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[700],
          onTap: _onNavItemTapped,
          backgroundColor: kMainColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                // TODO add filter functionality
                onChanged: null,
                decoration: InputDecoration(
                  hintText: 'Search gaming center...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.filter_alt_outlined),
                    onPressed: () {},
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: gamingCenters.length,
                  itemBuilder: (context, index) {
                    final center = gamingCenters[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CenterDetailsPage(centerId: center['id']),
                          ),
                        );
                      },
                      child: Card(
                        color: kMainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            center['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      if (_isLoading)
        Positioned.fill(
          child: Container(
            color:
                Colors.black.withValues(alpha: 0.5), // Semi-transparent overlay
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
    ]);
  }
}
