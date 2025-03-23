import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  _ClientHomePageState createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _openingTimeController = TextEditingController();
  final TextEditingController _closingTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _gameListController = TextEditingController();
  final TextEditingController _noticeListController = TextEditingController();

  int _selectedIndex = 0;
  bool _isEditingGameList = false;
  bool _isEditingNoticeList = false;
  bool _isEditingName = false;
  bool _isEditingLocation = false;

  String _userName = 'User';
  List<String> _games = [];
  List<String> _notices = [];

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    final responses = await Future.wait([
      supabase.from('profiles').select('name').eq('id', userId!).maybeSingle(),
      supabase
          .from('game_center')
          .select()
          .eq('client_id', userId)
          .maybeSingle(),
    ]);

    final userResponse = responses[0];
    final centerResponse = responses[1];

    setState(() {
      _userName = userResponse?['name'] ?? 'User';
      _nameController.text = centerResponse?['name'] ?? '';
      _openingTimeController.text = centerResponse?['opening_time'] ?? '';
      _closingTimeController.text = centerResponse?['closing_time'] ?? '';
      _locationController.text = centerResponse?['location'] ?? '';
      _games = List<String>.from(centerResponse?['games'] ?? []);
      _notices = List<String>.from(centerResponse?['notices'] ?? []);
    });
  }

  Future<void> logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveChanges(String field, dynamic value) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        CCustomSnackBar.show(context, 'User not logged in!', Colors.red);
        return;
      }

      // Check if a row exists for this user
      final response = await supabase
          .from('game_center')
          .select('id')
          .eq('client_id', userId)
          .maybeSingle();

      if (response == null) {
        // No row found, insert a new one
        final insertResponse = await supabase.from('game_center').insert({
          'client_id': userId,
          field: value,
        });

        if (insertResponse.error != null) {
          throw insertResponse.error!;
        }
      } else {
        // Row exists, update it
        final centerId = response['id'];
        await supabase
            .from('game_center')
            .update({field: value}).eq('id', centerId);
      }

      if (mounted) {
        setState(() {
          if (field == 'name') _isEditingName = false;
          if (field == 'location') _isEditingLocation = false;
        });
      }

      CCustomSnackBar.show(
          context, '$field updated successfully!', Colors.green);
    } catch (e) {
      debugPrint('Error updating $field: $e');
      CCustomSnackBar.show(context, 'Error updating $field', Colors.red);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initialOpeningTime = _openingTimeController.text.isNotEmpty
        ? _parseTime(_openingTimeController.text)
        : TimeOfDay.now();

    // Opening time picker
    TimeOfDay? openingTime = await showTimePicker(
      context: context,
      helpText: 'Choose Opening Time',
      initialTime: initialOpeningTime,
    );
    if (openingTime == null) return;

    // Closing time picker
    TimeOfDay? closingTime = await showTimePicker(
      context: context,
      helpText: 'Choose Closing Time',
      initialTime: openingTime,
    );
    if (closingTime == null) return;

    // Error SnackBar if invalid closing time
    if (!_isClosingTimeValid(openingTime, closingTime)) {
      CCustomSnackBar.show(
          context, 'Closing time must be after opening time!', Colors.orange);
      return;
    }

    // Formatting and Saving
    String openingTimeStr = _formatTime(openingTime);
    String closingTimeStr = _formatTime(closingTime);
    setState(() {
      _openingTimeController.text = openingTimeStr;
      _closingTimeController.text = closingTimeStr;
    });
    await _saveChanges('opening_time', openingTimeStr);
    await _saveChanges('closing_time', closingTimeStr);
  }

  TimeOfDay _parseTime(String timeStr) {
    final format =
        RegExp(r'(\d+):(\d+) (AM|PM)'); // Extracts hour, minute, and AM/PM
    final match = format.firstMatch(timeStr);

    if (match == null) return TimeOfDay.now(); // Default fallback

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    if (period == "PM" && hour != 12) hour += 12;
    if (period == "AM" && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
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

  Future<void> _saveGames() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      List<String> updatedGames = _gameListController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await supabase
          .from('game_center')
          .update({'games': updatedGames}).eq('client_id', userId);

      setState(() {
        _games = updatedGames;
        _isEditingGameList = false;
      });

      CCustomSnackBar.show(
          context, 'Games updated successfully!', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, 'Error updating games', Colors.red);
    }
  }

  Future<void> _saveNotices() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      List<String> updatedNotices = _noticeListController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await supabase
          .from('game_center')
          .update({'notices': updatedNotices}).eq('client_id', userId);

      setState(() {
        _notices = updatedNotices;
        _isEditingNoticeList = false;
      });

      CCustomSnackBar.show(
          context, 'Notices updated successfully!', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, 'Error updating Notices', Colors.red);
    }
  }

  bool _isClosingTimeValid(TimeOfDay opening, TimeOfDay closing) {
    return (closing.hour > opening.hour) ||
        (closing.hour == opening.hour && closing.minute > opening.minute);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _locationController.dispose();
    _gameListController.dispose();
    _noticeListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Hello, $_userName!',
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _isEditingName = false;
            _isEditingLocation = false;
            _isEditingGameList = false;
            _isEditingNoticeList = false;
          });
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                        decoration: BoxDecoration(
                          color: kMainColor,
                          borderRadius: BorderRadius.all(Radius.circular(48.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 7,
                              offset: Offset(1, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Center Name
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _isEditingName
                                    ? Expanded(
                                        child: TextField(
                                          style: TextStyle(color: Colors.white),
                                          controller: _nameController,
                                        ),
                                      )
                                    : Text(
                                        _nameController.text.isEmpty
                                            ? 'Gaming Center Name'
                                            : _nameController.text,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                IconButton(
                                  icon: Icon(
                                    _isEditingName ? Icons.check : Icons.edit,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    if (_isEditingName) {
                                      _saveChanges(
                                          'name', _nameController.text);
                                    }
                                    setState(
                                        () => _isEditingName = !_isEditingName);
                                  },
                                ),
                              ],
                            ),

                            // Timings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.watch_later_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Timings: ${_formatStoredTime(_openingTimeController.text)} - ${_formatStoredTime(_closingTimeController.text)}',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _pickTime(context); // Show the time picker
                                  },
                                ),
                              ],
                            ),

                            // Location
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _isEditingLocation
                                      ? TextField(
                                          style: TextStyle(color: Colors.white),
                                          controller: _locationController,
                                          maxLines:
                                              null, // Allows dynamic expansion
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        )
                                      : Text(
                                          _locationController.text.isEmpty
                                              ? 'Enter Location'
                                              : _locationController.text,
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                          softWrap: true,
                                        ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditingLocation
                                        ? Icons.check
                                        : Icons.edit,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    if (_isEditingLocation) {
                                      _saveChanges(
                                          'location', _locationController.text);
                                    }
                                    setState(() => _isEditingLocation =
                                        !_isEditingLocation);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Games List Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Games Available',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Games List with Proper Layout
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _games.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _games.map((game) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.sports_esports,
                                                    size: 20,
                                                    color: kMainColor),
                                                const SizedBox(width: 8),
                                                Text(game,
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : const Text(
                                        'No games added yet.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic),
                                      ),
                              ),

                              // Edit Icon Aligned to Bottom-Right
                              if (!_isEditingGameList)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: kMainColor, size: 24),
                                    onPressed: () {
                                      setState(() {
                                        _gameListController.text =
                                            _games.join(', ');
                                        _isEditingGameList = true;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Text Field and Confirm Icon for Editing
                          if (_isEditingGameList)
                            Column(
                              children: [
                                TextField(
                                  controller: _gameListController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter game names separated by commas',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Save Icon
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green, size: 28),
                                    onPressed: _saveGames, // Save function
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Notices List Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notices',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _notices.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _notices.map((notice) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.newspaper_rounded,
                                                    size: 20,
                                                    color: kMainColor),
                                                const SizedBox(width: 8),
                                                Text(notice,
                                                    style: const TextStyle(
                                                        fontSize: 14)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : const Text(
                                        'No notices added yet.',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic),
                                      ),
                              ),
                              if (!_isEditingNoticeList)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.add,
                                        color: kMainColor, size: 24),
                                    onPressed: () {
                                      setState(() {
                                        _noticeListController.text =
                                            _notices.join(', ');
                                        _isEditingNoticeList = true;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Text Field and Confirm Icon for Editing
                          if (_isEditingNoticeList)
                            Column(
                              children: [
                                TextField(
                                  controller: _noticeListController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter notices names separated by commas',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green, size: 28),
                                    onPressed: _saveNotices, // Save function
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
          ],
        ),
      ),
    );
  }
}
