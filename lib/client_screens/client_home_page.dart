import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/custom_widgets.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/helperFunctions/timeFormatting.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'client_bookings_page.dart';
import 'client_profile_page.dart';

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
  bool _isEditingName = false;
  bool _isEditingLocation = false;
  bool _isLoading = false;
  int? _editingIndex;
  bool _isAddingNotice = false;

  String _userName = 'User';
  List<String> _games = [];
  List<String> _notices = [];
  int _seatCount = 1;

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

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

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
      _seatCount = centerResponse?['seat_count'] ?? 1;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _saveCenterInfoChanges(String field, dynamic value) async {
    setState(() {
      _isLoading = true;
    });
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initialOpeningTime = _openingTimeController.text.isNotEmpty
        ? parseTime(_openingTimeController.text)
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
    if (!isClosingTimeValid(openingTime, closingTime)) {
      CCustomSnackBar.show(
          context, 'Closing time must be after opening time!', Colors.orange);
      return;
    }

    // Formatting and Saving
    String openingTimeStr = formatTime(openingTime);
    String closingTimeStr = formatTime(closingTime);
    setState(() {
      _openingTimeController.text = openingTimeStr;
      _closingTimeController.text = closingTimeStr;
    });
    await _saveCenterInfoChanges('opening_time', openingTimeStr);
    await _saveCenterInfoChanges('closing_time', closingTimeStr);
  }

  Future<void> _saveGamesList() async {
    setState(() {
      _isLoading = true;
    });
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
        _isLoading = false;
      });

      CCustomSnackBar.show(
          context, 'Games updated successfully!', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, 'Error updating games', Colors.red);
    }
  }

  Future<void> _saveNotices() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      _notices.removeWhere((notice) => notice.trim().isEmpty);

      await supabase
          .from('game_center')
          .update({'notices': _notices}).eq('client_id', userId);

      CCustomSnackBar.show(
          context, 'Notices updated successfully!', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, 'Error updating Notices', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateEditedNoticeToList(int index) {
    setState(() {
      _notices[index] = _noticeListController.text.trim();
      if (_notices[index].isEmpty) {
        _notices.removeAt(index);
      }
      _editingIndex = null;
    });
    _saveNotices();
  }

  void _updateNewNoticeToList() {
    setState(() {
      String newNotice = _noticeListController.text.trim();
      if (newNotice.isNotEmpty) {
        _notices.add(newNotice);
        _isAddingNotice = false;
      }
    });
    _saveNotices();
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
    return Stack(children: [
      AbsorbPointer(
        absorbing: _isLoading,
        child: Scaffold(
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
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _isEditingName = false;
                _isEditingLocation = false;
                _isEditingGameList = false;
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
                            decoration: kCenterInfoBox,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Center Name
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _isEditingName
                                        ? Expanded(
                                            child: TextField(
                                              style: TextStyle(
                                                  color: Colors.white),
                                              controller: _nameController,
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.grey),
                                                ),
                                              ),
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
                                        _isEditingName
                                            ? Icons.check
                                            : Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_isEditingName) {
                                            // Save only when toggling from edit mode to normal mode
                                            _saveCenterInfoChanges(
                                                'name', _nameController.text);
                                          }
                                          _isEditingName =
                                              !_isEditingName; // Toggle edit mode
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                // Timings
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.watch_later_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Timings: ${formatStoredTime(_openingTimeController.text)} - ${formatStoredTime(_closingTimeController.text)}',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        _pickTime(
                                            context); // Show the time picker
                                      },
                                    ),
                                  ],
                                ),

                                // Location
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: _isEditingLocation
                                          ? TextField(
                                              style: TextStyle(
                                                  color: Colors.white),
                                              controller: _locationController,
                                              maxLines: null,
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.grey),
                                                ),
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
                                        setState(() {
                                          if (_isEditingLocation) {
                                            _saveCenterInfoChanges('location',
                                                _locationController.text);
                                          }
                                          _isEditingLocation =
                                              !_isEditingLocation;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Number of seats

                          const SizedBox(height: 32),
                          // Games List Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Games Available',
                                    style: kHeaderStyle,
                                  ),
                                  _isEditingGameList
                                      ? IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green, size: 28),
                                          onPressed: () {
                                            _saveGamesList();
                                          },
                                        )
                                      : IconButton(
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
                                ],
                              ),

                              // List
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .sports_esports_outlined,
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
                                  ],
                                ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Notices List Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notices',
                                style: kHeaderStyle,
                              ),

                              // Notices List
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < _notices.length; i++)
                                    if (_notices[i].trim().isNotEmpty)
                                      // Existing Notices
                                      Row(
                                        children: [
                                          const Icon(Icons.newspaper_rounded,
                                              size: 20, color: kMainColor),
                                          const SizedBox(width: 8),
                                          _editingIndex == i
                                              ? Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _noticeListController,
                                                    autofocus: true,
                                                    decoration:
                                                        const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                  ),
                                                )
                                              : Expanded(
                                                  child: Text(
                                                    _notices[i],
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ),
                                          IconButton(
                                            icon: Icon(
                                              _editingIndex == i
                                                  ? Icons.check
                                                  : Icons.edit,
                                              color: _editingIndex == i
                                                  ? Colors.green
                                                  : kMainColor,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_editingIndex == i) {
                                                  _updateEditedNoticeToList(i);
                                                } else {
                                                  _noticeListController.text =
                                                      _notices[i];
                                                  _editingIndex = i;
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),

                                  // Add new notice input field
                                  if (_isAddingNotice)
                                    Row(
                                      children: [
                                        const Icon(Icons.newspaper_rounded,
                                            size: 20, color: kMainColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _noticeListController,
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter new notice',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.check,
                                              color: Colors.green, size: 24),
                                          onPressed: () {
                                            _updateNewNoticeToList();
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              // Add new notice button
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.add,
                                      color: kMainColor, size: 24),
                                  onPressed: () {
                                    setState(() {
                                      _noticeListController.clear();
                                      _isAddingNotice = true;
                                    });
                                  },
                                ),
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
