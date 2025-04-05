import 'package:book_my_slot/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'package:book_my_slot/customer_screens/center_search_page.dart';
import 'package:book_my_slot/customer_screens/cust_profile_page.dart';
import 'package:book_my_slot/customer_screens/your_bookings.dart';

class DateTimePage extends StatefulWidget {
  const DateTimePage({super.key});

  @override
  _DateTimePageState createState() => _DateTimePageState();
}

class _DateTimePageState extends State<DateTimePage> {
  int selectedSeats = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select date & time'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Column(
                  children: [
                    Text('MON\n${17 + index}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('FEB'),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                '10-11am',
                '11-12pm',
                '12-1pm',
                '1-2pm',
                '2-3pm',
                '3-4pm',
                '4-5pm',
                '5-6pm',
                '6-7pm'
              ]
                  .map((time) => ChoiceChip(
                        label: Text(time),
                        selected: false,
                        onSelected: (bool selected) {},
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (selectedSeats > 1) selectedSeats--;
                    });
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text('$selectedSeats'),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedSeats++;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(300, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {},
              child: const Text('Book Slot'),
            ),
          ],
        ),
      ),
    );
  }
}

class SlotSelectionPage extends StatefulWidget {
  final dynamic centerId;

  const SlotSelectionPage({super.key, required this.centerId});

  @override
  _SlotSelectionPageState createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  List<String> availableSlots = [];
  dynamic selectedSlot;
  bool _isLoading = false;
  int _selectedIndex = 0;

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
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    final response = await Supabase.instance.client
        .from('slots')
        .select('id')
        .eq('id', widget.centerId)
        .eq('isBooked', false);

    setState(() {
      availableSlots =
          response.map<String>((slot) => slot['id'].toString()).toList();
    });
  }

  Future<void> _bookSlot() async {
    if (selectedSlot == null) return;

    await Supabase.instance.client
        .from('slots')
        .update({'isBooked': true}).match({'id': selectedSlot});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Slot Selection',
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
                        const Text(
                          'Select a Slot:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = availableSlots[index];
                              return RadioListTile<String>(
                                title: Text(slot),
                                value: slot,
                                groupValue: selectedSlot,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSlot = value;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Spacer(),
                        CCustomButton(
                            buttonColor: kMainColor,
                            textColor: Colors.white,
                            text: 'Confirm Booking',
                            onPressed: () {}),
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
