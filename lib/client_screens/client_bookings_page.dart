import 'package:book_my_slot/client_screens/client_home_page.dart';
import 'package:book_my_slot/client_screens/client_profile_page.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'package:book_my_slot/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientBookingsPage extends StatefulWidget {
  const ClientBookingsPage({super.key});

  @override
  State<ClientBookingsPage> createState() => _ClientBookingsPageState();
}

class _ClientBookingsPageState extends State<ClientBookingsPage> {
  bool _isLoading = false;
  int _selectedIndex = 1;
  DateTime selectedDate = DateTime.now();
  final supabase = Supabase.instance.client;

  late String centerId;
  late List<Map<String, String>> dateStrip;
  List<dynamic> _bookings = [];

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
        nextPage = const ClientHomePage();
        break;
      case 1:
        nextPage = const ClientBookingsPage();
        break;
      case 2:
        nextPage = const ClientProfilePage();
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

  void _generateDatesStrip() {
    setState(() => _isLoading = true);

    final today = DateTime.now();
    dateStrip = List.generate(7, (index) {
      final date = today.add(Duration(days: index));
      return {
        'day': DateFormat.E().format(date),
        'date': DateFormat.d().format(date),
        'month': DateFormat.MMM().format(date),
      };
    });

    setState(() => _isLoading = false);
  }

  void _getCenterId() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('game_center')
        .select('id')
        .eq('client_id', userId!)
        .single();
    centerId = (response['id'] as String?)!;
    _fetchBookings();
  }

  @override
  void initState() {
    super.initState();
    _generateDatesStrip();
    _getCenterId();
  }

  void _fetchBookings() async {
    setState(() => _isLoading = true);

    final startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    final response = await supabase
        .from('bookings')
        .select('seat_count, start_time, cust_id')
        .gte('start_time', startOfDay.toIso8601String())
        .lte('start_time', endOfDay.toIso8601String())
        .eq('center_id', centerId);

    List<Map<String, dynamic>> bookings =
        response.toList().map<Map<String, dynamic>>((booking) {
      DateTime startTime = DateTime.parse(booking['start_time']);
      DateTime endTime = startTime.add(const Duration(hours: 1));

      String formattedStartTime = DateFormat.jm().format(startTime);
      String formattedEndTime = DateFormat.jm().format(endTime);

      return {
        'seats': booking['seat_count'],
        'time': '$formattedStartTime - $formattedEndTime',
        'name': null,
        'phone': null,
        'uid': booking['cust_id'],
      };
    }).toList();

    for (var booking in bookings) {
      final uid = booking['uid'];

      final profileResponse = await supabase
          .from('profiles')
          .select('name, phone')
          .eq('id', uid)
          .maybeSingle();

      if (profileResponse != null) {
        booking['name'] = profileResponse['name'];
        booking['phone'] = profileResponse['phone'];
      }
    }

    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Bookings',
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
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
                        // Day selection
                        SizedBox(
                          height: 88,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6.0),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: dateStrip.length,
                              itemBuilder: (context, index) {
                                final item = dateStrip[index];
                                final isSelected =
                                    selectedDate.day.toString() ==
                                            item['date'] &&
                                        DateFormat.E().format(selectedDate) ==
                                            item['day'];

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedDate = DateTime.now()
                                          .add(Duration(days: index));
                                      _fetchBookings();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? kMainColor
                                          : Colors.white,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['day']!.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w200,
                                          ),
                                        ),
                                        Text(
                                          '${item['date']}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        Text(
                                          item['month']!.toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.w200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Bookings Table
                        _bookings.isEmpty
                            ? const Center(
                                child: Text('No bookings for this day'))
                            : Table(
                                border: TableBorder.all(color: Colors.black),
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(1.7),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(2.5),
                                },
                                children: [
                                  const TableRow(
                                    decoration:
                                        BoxDecoration(color: Color(0xFFE0E0E0)),
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Seats',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Name',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Phone no.',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text('Time',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  for (var booking in _bookings)
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            booking['seats'].toString(),
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            booking['name'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            booking['phone'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            booking['time'],
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
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
