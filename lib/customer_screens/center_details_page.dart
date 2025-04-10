import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'center_search_page.dart';
import 'cust_profile_page.dart';
import 'your_bookings.dart';
import 'slot_booking_page.dart';

class CenterDetailsPage extends StatefulWidget {
  final String centerId;

  const CenterDetailsPage({super.key, required this.centerId});

  @override
  State<CenterDetailsPage> createState() => _CenterDetailsPageState();
}

class _CenterDetailsPageState extends State<CenterDetailsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  bool _isLoading = false;

  Map<String, dynamic>? centerDetails;
  String _centerName = 'Center Name';
  String _openingTime = '';
  String _closingTime = '';
  String _location = '';
  List<String> _games = [];
  List<String> _notices = [];

  Future<void> logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final responses = await supabase
        .from('game_center')
        .select()
        .eq('id', widget.centerId)
        .maybeSingle();

    setState(() {
      _centerName = responses?['name'] ?? '';
      _openingTime = responses?['opening_time'] ?? '';
      _closingTime = responses?['closing_time'] ?? '';
      _location = responses?['location'] ?? '';
      _games = List<String>.from(responses?['games'] ?? []);
      _notices = List<String>.from(responses?['notices'] ?? []);
      _isLoading = false;
    });
  }

  String _formatTime(TimeOfDay time) {
    final int hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod; // Convert 0 to 12
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final String minute =
        time.minute.toString().padLeft(2, '0'); // Ensure 2 digits

    return '$hour:$minute $period';
  }

  String _formatStoredTime(String timeStr) {
    try {
      List<String> parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
      return _formatTime(time); // Use your existing _formatTime function
    } catch (e) {
      return timeStr; // Return original in case of an error
    }
  }

  bool _isCenterOpen() {
    try {
      final now = TimeOfDay.now();
      final opening = _parseTimeOfDay(_openingTime);
      final closing = _parseTimeOfDay(_closingTime);

      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = opening.hour * 60 + opening.minute;
      final closeMinutes = closing.hour * 60 + closing.minute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } catch (e) {
      return false; // Fallback in case of parse error
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Center Details',
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
              BottomNavigationBarItem(
                  icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.book), label: 'Bookings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
          body: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Center Information
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 32,
                          ),
                          decoration: kCenterInfoBox,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Center Name
                              Text(
                                _centerName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16.0),
                              // Timings
                              Row(
                                children: [
                                  if (_isCenterOpen()) ...[
                                    Icon(Icons.circle,
                                        color: Colors.green, size: 12),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Open now',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    const SizedBox(width: 16),
                                  ] else ...[
                                    Icon(Icons.circle,
                                        color: Colors.red, size: 12),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Closed',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    '${_formatStoredTime(_openingTime)} - ${_formatStoredTime(_closingTime)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.0),
                              // Location
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _location,
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Games List Section
                        CCustomListBuilder(
                            list: _games,
                            icon: Icons.sports_esports_rounded,
                            listType: 'games'),
                        SizedBox(height: 24),

                        // Notices List Section
                        CCustomListBuilder(
                          list: _notices,
                          icon: Icons.newspaper_rounded,
                          listType: 'notices',
                        ),

                        Spacer(),
                        CCustomButton(
                            buttonColor: kMainColor,
                            textColor: Colors.white,
                            text: 'Book Now',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SlotSelectionPage(
                                          centerId: widget.centerId,
                                        )),
                              );
                            })
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
