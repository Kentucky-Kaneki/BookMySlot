import 'package:book_my_slot/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/login_screens/welcome_page.dart';
import 'client_home_page.dart';
import 'client_bookings_page.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;
  int _selectedIndex = 2;

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

  Future<void> saveProfile() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'name': nameController.text,
        'phone': phoneController.text,
      }).eq('id', user.id);

      CCustomSnackBar.show(context, 'Saved Successfully', Colors.green);
    } catch (e) {
      CCustomSnackBar.show(context, e.toString(), Colors.red);
    }
    setState(() => isLoading = false);
  }

  Future<void> loadProfile() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Profile Page',
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextField(
                            controller: nameController,
                            decoration:
                                const InputDecoration(labelText: 'Name')),
                        TextField(
                            controller: phoneController,
                            decoration:
                                const InputDecoration(labelText: 'Phone')),
                        Spacer(),
                        CCustomButton(
                            buttonColor: kMainColor,
                            textColor: Colors.white,
                            text: 'Save Profile',
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              saveProfile();
                            })
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        if (isLoading)
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
