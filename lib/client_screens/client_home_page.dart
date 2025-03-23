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
  final TextEditingController _gameController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();

  int _selectedIndex = 0;
  bool _showGameInput = false;
  bool _showNoticeInput = false;
  bool _isEditingName = false;
  bool _isEditingLocation = false;

  String _userName = 'User';
  List<String> _games = [];
  List<String> _notices = [];
  String? _editingGame;

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;

    final userResponse =
        await supabase.from('game_center').select('name').single();
    setState(() {
      _userName = userResponse['name'] ?? 'User';
    });

    final gameResponse = await supabase.from('games').select();
    final noticeResponse = await supabase.from('notices').select();
    final centerResponse = await supabase.from('game_center').select().single();

    setState(() {
      _games = gameResponse.map<String>((g) => g['name'] as String).toList();
      _notices =
          noticeResponse.map<String>((n) => n['text'] as String).toList();
      _nameController.text = centerResponse['name'];
      _openingTimeController.text = centerResponse['opening_time'] ?? '';
      _closingTimeController.text = centerResponse['closing_time'] ?? '';
      _locationController.text = centerResponse['location'];
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

      await supabase.from('game_center').update({field: value}).eq(
          'id', 'YOUR_CENTER_ID'); // Replace with actual center ID

      setState(() {
        if (field == 'name') _isEditingName = false;
        if (field == 'location') _isEditingLocation = false;
      });

      CCustomSnackBar.show(
          context, '$field updated successfully!', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, 'Error updating $field', Colors.red);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    // Opening time picker
    TimeOfDay? openingTime = await showTimePicker(
      context: context,
      initialTime: _openingTimeController.text.isNotEmpty
          ? _parseTime(_openingTimeController.text)
          : TimeOfDay.now(),
    );
    if (openingTime == null) return;

    // Closing time picker
    TimeOfDay? closingTime = await showTimePicker(
      context: context,
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
    await _saveChanges('timings', {
      'opening_time': openingTimeStr,
      'closing_time': closingTimeStr,
    });
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
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  bool _isClosingTimeValid(TimeOfDay opening, TimeOfDay closing) {
    return (closing.hour > opening.hour) ||
        (closing.hour == opening.hour && closing.minute > opening.minute);
  }

  Future<void> _addGame() async {
    if (_gameController.text.trim().isEmpty) return;
    final supabase = Supabase.instance.client;
    await supabase.from('games').insert({'name': _gameController.text.trim()});

    setState(() {
      _games.add(_gameController.text.trim());
      _gameController.clear();
      _showGameInput = false;
    });
  }

  Future<void> _updateGame(String oldName, String newName) async {
    final supabase = Supabase.instance.client;
    await supabase.from('games').update({'name': newName}).eq('name', oldName);

    setState(() {
      int index = _games.indexOf(oldName);
      if (index != -1) _games[index] = newName;
      _editingGame = null;
    });
  }

  Future<void> _addNotice() async {
    if (_noticeController.text.trim().isEmpty) return;
    final supabase = Supabase.instance.client;
    await supabase
        .from('notices')
        .insert({'text': _noticeController.text.trim()});

    setState(() {
      _notices.add(_noticeController.text.trim());
      _noticeController.clear();
      _showNoticeInput = false;
    });
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
    _gameController.dispose();
    _noticeController.dispose();
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
            _showGameInput = false;
            _showNoticeInput = false;
            _editingGame = null;
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
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: kMainColor,
                          borderRadius: BorderRadius.circular(8.0),
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
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Enter Gaming Center Name',
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _nameController.text.isEmpty
                                            ? 'Gaming Center Name'
                                            : _nameController.text,
                                        style: TextStyle(
                                          fontSize: 18,
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
                            const SizedBox(height: 8),

                            // Timings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_openingTimeController.text} - ${_closingTimeController.text}',
                                  style: TextStyle(color: Colors.white),
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
                            const SizedBox(height: 8),

                            // Location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    _isEditingLocation
                                        ? SizedBox(
                                            width: 200,
                                            child: TextField(
                                              controller: _locationController,
                                              decoration: const InputDecoration(
                                                  hintText: 'Enter location'),
                                            ),
                                          )
                                        : Text(
                                            _locationController.text.isEmpty
                                                ? 'Gaming Center Location'
                                                : _locationController.text,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ],
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
                      const SizedBox(height: 24),

                      // Games
                      const Text(
                        'Games Available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Column(
                        children: _games.map((game) {
                          bool isEditing = _editingGame == game;
                          TextEditingController controller =
                              TextEditingController(text: game);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _editingGame = game;
                              });
                            },
                            child: isEditing
                                ? TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Edit game name',
                                    ),
                                    onSubmitted: (newValue) async {
                                      if (newValue.trim().isNotEmpty &&
                                          newValue != game) {
                                        await _updateGame(
                                            game, newValue.trim());
                                      }
                                      setState(() {
                                        _editingGame = null;
                                      });
                                    },
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      game,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                          );
                        }).toList(),
                      ),
                      if (_showGameInput)
                        TextField(
                          controller: _gameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                              hintText: 'Enter game name'),
                          onSubmitted: (_) async {
                            await _addGame();
                            setState(() {
                              _showGameInput = false;
                            });
                          },
                        ),
                      TextButton(
                        onPressed: () => setState(() => _showGameInput = true),
                        child: const Text('+ Add game'),
                      ),
                      const SizedBox(height: 24),

                      // Notices
                      const Text(
                        'Notices',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      ..._notices.map((notice) => Text(notice)).toList(),
                      if (_showNoticeInput)
                        TextField(
                          controller: _noticeController,
                          decoration:
                              const InputDecoration(hintText: 'Enter notice'),
                          onSubmitted: (_) => _addNotice(),
                        ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showNoticeInput = true),
                        child: const Text('+ Add Notice'),
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
