import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'package:book_my_slot/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'center_search_page.dart';
import 'cust_profile_page.dart';
import 'package:book_my_slot/custom_widgets.dart';

class YourBookings extends StatefulWidget {
  const YourBookings({super.key});

  @override
  State<YourBookings> createState() => _YourBookingsState();
}

class _YourBookingsState extends State<YourBookings> {
  bool _isLoading = false;
  int _selectedIndex = 1;
  final supabase = Supabase.instance.client;

  List<dynamic> bookings = [];

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

  void _fetchBookings() async {
    setState(() => _isLoading = true);
    final custId = supabase.auth.currentUser?.id;

    final response = await supabase
        .from('bookings')
        .select('id, center_id, start_time, seat_count')
        .eq('cust_id', custId!);

    List<Map<String, dynamic>> fetchedBookings =
        response.toList().map<Map<String, dynamic>>((booking) {
      DateTime startTime = DateTime.parse(booking['start_time']);
      DateTime endTime = startTime.add(const Duration(hours: 1));

      String formattedDate = DateFormat('EEEE dd MMMM').format(startTime);
      String formattedStartTime = DateFormat.jm().format(startTime);
      String formattedEndTime = DateFormat.jm().format(endTime);

      return {
        'id': booking['id'],
        'seats': booking['seat_count'],
        'date': formattedDate,
        'time': '$formattedStartTime - $formattedEndTime',
        'center name': null,
        'center_id': booking['center_id'],
      };
    }).toList();

    for (var booking in fetchedBookings) {
      final uid = booking['center_id'];

      final centerResponse = await supabase
          .from('game_center')
          .select('name')
          .eq('id', uid)
          .single();

      booking['center name'] = centerResponse['name'];
    }

    setState(() {
      bookings = fetchedBookings;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _cancelTicket(String bookingId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      await supabase.from('bookings').delete().eq('id', bookingId);

      setState(() {
        _fetchBookings();
        _isLoading = false;
      });

      CCustomSnackBar.show(
          context, 'Booking Cancelled Successful', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Your Bookings',
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
                    child: bookings.isEmpty
                        ? const Center(
                            child: Text(
                              "You haven't booked any slots.\nStart Booking Now!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: bookings.map((booking) {
                              return Ticket(
                                booking: booking,
                                onPressed: () => _cancelTicket(booking['id']),
                              );
                            }).toList(),
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

class Ticket extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onPressed;

  const Ticket({Key? key, required this.booking, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
      decoration: kCustomBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking['center name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            booking['date'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            booking['time'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            '${booking['seats']} Seat${booking['seats'] > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Confirmed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onPressed,
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
