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
  late DateTime startOfDay;
  late DateTime endOfDay;
  int totalSeats = 0;

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

  @override
  void initState() {
    super.initState();
    _generateDatesStrip();
    _generateSlots();
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

  // TODO Not fetching/getting available seats properly
  Future<void> _generateSlots() async {
    final supabase = Supabase.instance.client;
    setState(() => _isLoading = true);

    final response = await supabase
        .from('game_center')
        .select('opening_time, closing_time, seat_count')
        .eq('id', widget.centerId)
        .single();

    final openingTime =
        DateTime.parse('2000-01-01 ${response['opening_time']}');
    final closingTime =
        DateTime.parse('2000-01-01 ${response['closing_time']}');

    totalSeats = response['seat_count'];

    startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      openingTime.hour,
      openingTime.minute,
    );

    endOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      closingTime.hour,
      closingTime.minute,
    );

    final startOfDayUtc = startOfDay.toUtc().toIso8601String();
    final endOfDayUtc = endOfDay.toUtc().toIso8601String();

    final bookingsResponse = await supabase
        .from('bookings')
        .select('start_time, seat_count')
        .eq('center_id', widget.centerId)
        .gte('start_time', startOfDayUtc)
        .lt('start_time', endOfDayUtc);

    final List<Map<String, dynamic>> bookedSlots =
        List<Map<String, dynamic>>.from(bookingsResponse);

    final Map<DateTime, int> bookedSeatCountByTime = {};
    for (final booking in bookedSlots) {
      final startRaw = DateTime.parse(booking['start_time']).toLocal();
      final start = DateTime(
        startRaw.year,
        startRaw.month,
        startRaw.day,
        startRaw.hour,
        0,
        0,
        0,
      );
      final count = booking['seat_count'] as int? ?? 0;

      if (bookedSeatCountByTime.containsKey(start)) {
        bookedSeatCountByTime[start] = bookedSeatCountByTime[start]! + count;
      } else {
        bookedSeatCountByTime[start] = count;
      }
      print('Booking: ${start.toIso8601String()} => $count seats');
    }

    final List<Map<String, dynamic>> generatedSlots = [];

    // Generate 1-hour slots
    DateTime current = startOfDay;
    while (current.isBefore(endOfDay)) {
      final next = current.add(const Duration(hours: 1));

      final normalizedStart = DateTime(
        current.year,
        current.month,
        current.day,
        current.hour,
        0,
        0,
        0,
      );

      final totalBookedSeats = bookedSeatCountByTime[normalizedStart] ?? 0;
      final availableSeats = totalSeats - totalBookedSeats;

      final isToday = selectedDate.year == DateTime.now().year &&
          selectedDate.month == DateTime.now().month &&
          selectedDate.day == DateTime.now().day;

      final isPast = isToday && current.isBefore(DateTime.now());

      generatedSlots.add({
        'label':
            '${DateFormat.jm().format(current)} - ${DateFormat.jm().format(next)}',
        'start': current,
        'end': next,
        'availableSeats': availableSeats,
        'isBooked': availableSeats <= 0,
        'isPast': isPast
      });
      current = next;
      print('Slot: ${current.toIso8601String()} => ${totalBookedSeats} booked');
    }

    setState(() {
      slots = generatedSlots;
      _isLoading = false;
    });
  }

  Future<void> _confirmBooking() async {
    final supabase = Supabase.instance.client;

    if (selectedSlotId == null) {
      CCustomSnackBar.show(context, 'Select a Slot', Colors.orange);
      return;
    }

    try {
      final user = supabase.auth.currentUser;

      final start = selectedSlotId['start'] as DateTime;

      await supabase.from('bookings').insert({
        'start_time': start.toIso8601String(),
        'seat_count': _seatCount,
        'cust_id': user?.id,
        'center_id': widget.centerId,
      });

      CCustomSnackBar.show(context, 'Booking Confirmed!', Colors.green);

      _generateSlots();
      setState(() {
        selectedSlotId = null;
        _seatCount = 1;
      });
    } catch (e) {
      CCustomSnackBar.show(
          context, 'Booking failed: ${e.toString()}', Colors.red);
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
                                      _generateSlots();
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
                              final isPast = slot['isPast'] == true;
                              final bool isDisabled = isBooked || isPast;

                              Color? backgroundColor;
                              final int available = slot['availableSeats'];

                              if (isPast) {
                                backgroundColor = Colors.grey.shade300;
                              } else if (isBooked) {
                                backgroundColor = Colors.red;
                              } else if (isSelected) {
                                backgroundColor = kMainColor;
                              } else {
                                final double ratio = available / totalSeats;
                                if (ratio <= 0.33) {
                                  backgroundColor = Colors.orange.shade300;
                                } else if (ratio <= 0.66) {
                                  backgroundColor = Colors.yellow.shade300;
                                } else {
                                  backgroundColor = null;
                                }
                              }

                              return ChoiceChip(
                                label: Text(
                                  '${slot['label']}: $available left',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                labelStyle: TextStyle(
                                  color: isPast
                                      ? Colors.grey.shade600
                                      : (backgroundColor == null)
                                          ? Colors.black
                                          : Colors.white,
                                ),
                                selected: isSelected,
                                onSelected: isDisabled
                                    ? (_) {
                                        final msg = isBooked
                                            ? 'Slot Fully Booked, cannot select'
                                            : 'Cannot Book';
                                        CCustomSnackBar.show(
                                            context, msg, Colors.orange);
                                      }
                                    : (_) {
                                        setState(() {
                                          selectedSlotId = slot;
                                        });
                                      },
                                selectedColor: kMainColor,
                                backgroundColor: backgroundColor,
                                showCheckmark: false,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Number of seats
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            children: [
                              Text(
                                'Select no. of seats',
                                style: kHeaderStyle,
                              ),
                              SizedBox(width: 80),
                              CCustomIconButton(
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
                              CCustomIconButton(
                                icon: Icons.add,
                                onPressed: () {
                                  setState(() {
                                    _seatCount++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        Spacer(),
                        CCustomButton(
                            buttonColor: (_seatCount >
                                    (selectedSlotId?['availableSeats'] ??
                                        totalSeats))
                                ? Colors.grey
                                : kMainColor,
                            textColor: Colors.white,
                            text: 'Confirm Booking',
                            onPressed: () {
                              if (_seatCount >
                                  (selectedSlotId?['availableSeats'] ??
                                      totalSeats)) {
                                CCustomSnackBar.show(
                                    context,
                                    'Cannot book more than ${selectedSlotId?['availableSeats'] ?? totalSeats} seats',
                                    Colors.orange);
                              } else {
                                _confirmBooking();
                              }
                            }),
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
