import 'package:book_my_slot/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'package:book_my_slot/customer_screens/center_search_page.dart';
import 'package:book_my_slot/customer_screens/cust_profile_page.dart';
import 'package:book_my_slot/customer_screens/your_bookings.dart';

class SlotSelectionPage extends StatefulWidget {
  final dynamic centerId;

  const SlotSelectionPage({super.key, required this.centerId});

  @override
  _SlotSelectionPageState createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  bool _isLoading = false;
  int _selectedIndex = 0;
  int _seatCount = 1;
  DateTime selectedDate = DateTime.now();
  late List<Map<String, String>> dateStrip;
  List<Map<String, dynamic>> slots = [];
  dynamic selectedSlotId;

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

  Future<void> generateSlots() async {
    final supabase = Supabase.instance.client;
    setState(() => _isLoading = true);

    // Get opening and closing times
    final response = await supabase
        .from('game_center')
        .select('opening_time, closing_time')
        .eq('id', widget.centerId)
        .single();

    final openingTime =
        DateTime.parse('2000-01-01 ${response['opening_time']}');
    final closingTime =
        DateTime.parse('2000-01-01 ${response['closing_time']}');

    // Combine with selectedDate to create full DateTime objects
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      openingTime.hour,
      openingTime.minute,
    );

    final endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      closingTime.hour,
      closingTime.minute,
    );

    // Fetch booked slots for this center
    final bookedResponse = await supabase
        .from('bookings')
        .select('start_time')
        .eq('center_id', widget.centerId);

    final List<Map<String, dynamic>> bookedSlots =
        List<Map<String, dynamic>>.from(bookedResponse).where((slot) {
      final start = DateTime.parse(slot['start_time']);
      return start.year == selectedDate.year &&
          start.month == selectedDate.month &&
          start.day == selectedDate.day;
    }).toList();

    final List<Map<String, dynamic>> generatedSlots = [];

    // Generate 1-hour slots
    DateTime current = startOfDay;
    while (current.isBefore(endOfDay)) {
      final next = current.add(const Duration(hours: 1));

      final isBooked = bookedSlots.any((booked) {
        final bookedStart = DateTime.parse(booked['start_time']);
        return bookedStart.isAtSameMomentAs(current);
      });

      generatedSlots.add({
        'label':
            '${DateFormat.jm().format(current)} - ${DateFormat.jm().format(next)}',
        'start': current,
        'end': next,
        'isBooked': isBooked,
      });

      current = next;
    }

    setState(() {
      slots = generatedSlots;
      _isLoading = false;
    });
  }

  void generateDatesStrip() {
    setState(() {
      _isLoading = true;
    });
    final today = DateTime.now();
    dateStrip = List.generate(7, (index) {
      final date = today.add(Duration(days: index));
      return {
        'day': DateFormat.E().format(date), // e.g. Mon, Tue
        'date': DateFormat.d().format(date), // e.g. 17
        'month': DateFormat.MMM().format(date), // e.g. Apr
      };
    });
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> confirmBooking() async {
    final supabase = Supabase.instance.client;

    if (selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a slot')),
      );
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final start = selectedSlotId['start'] as DateTime;
      final end = selectedSlotId['end'] as DateTime;

      await supabase.from('bookings').insert({
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'seats_count': _seatCount,
        'cust_id': user.id,
        'center_id': widget.centerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed!')),
      );

      // Refresh slots to reflect new booking
      generateSlots();
      setState(() {
        selectedSlotId = null;
        _seatCount = 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    generateDatesStrip();
    generateSlots();
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Day selection
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: dateStrip.length,
                            itemBuilder: (context, index) {
                              final item = dateStrip[index];
                              final isSelected =
                                  selectedDate.day.toString() == item['date'] &&
                                      DateFormat.E().format(selectedDate) ==
                                          item['day'];

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedDate = DateTime.now()
                                        .add(Duration(days: index));
                                    generateSlots();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? kMainColor : Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      const SizedBox(height: 4),
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
                                      const SizedBox(height: 4),
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

                        const SizedBox(height: 32),
                        // Slots selection
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 8,
                            runSpacing: 8,
                            children: slots.map((slot) {
                              final isSelected = slot == selectedSlotId;
                              final isBooked = slot['isBooked'] == true;

                              return ChoiceChip(
                                label: Text(
                                  slot['label'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                                labelStyle: TextStyle(
                                  color: isBooked
                                      ? Colors.grey.shade600
                                      : (isSelected
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                selected: isSelected,
                                onSelected: isBooked
                                    ? null // disables interaction
                                    : (_) {
                                        setState(() {
                                          selectedSlotId = slot;
                                        });
                                      },
                                selectedColor: isBooked
                                    ? Colors.grey.shade300
                                    : kMainColor,
                                backgroundColor:
                                    isBooked ? Colors.grey.shade300 : null,
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Number of seats
                        Row(
                          children: [
                            Text(
                              'Select no. of seats',
                              style: kHeaderStyle,
                            ),
                            SizedBox(width: 100),
                            SeatCountIcon(
                              icon: Icons.remove,
                              onPressed: () {
                                if (_seatCount > 1) {
                                  setState(() {
                                    _seatCount--;
                                  });
                                }
                              },
                            ),
                            SizedBox(width: 10),
                            Text(
                              '$_seatCount',
                              style: kHeaderStyle,
                            ),
                            SizedBox(width: 10),
                            SeatCountIcon(
                              icon: Icons.add,
                              onPressed: () {
                                //  TODO add seat count check functionality
                                if (true) {
                                  setState(() {
                                    _seatCount++;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        Spacer(),
                        CCustomButton(
                          buttonColor: kMainColor,
                          textColor: Colors.white,
                          text: 'Confirm Booking',
                          onPressed: confirmBooking,
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
