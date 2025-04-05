import 'package:flutter/material.dart';
import 'package:book_my_slot/constants.dart';
import 'center_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> gamingCenters = [];
  List<String> filteredCenters = [];

  @override
  void initState() {
    super.initState();
    _loadGamingCenters();
  }

  void _loadGamingCenters() {
    setState(() {
      gamingCenters =
          getGamingCentersFromClients(); // Fetch from database or API
      filteredCenters = gamingCenters;
    });
  }

  void _filterCenters(String query) {
    setState(() {
      filteredCenters = gamingCenters
          .where((center) => center.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserClient(), // Check if user is a client
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Find Gaming Center'),
            centerTitle: true,
            backgroundColor: kMainColor,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 0,
            selectedItemColor: kMainColor,
            onTap: (index) {},
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.book), label: 'Bookings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filterCenters,
                  decoration: InputDecoration(
                    hintText: 'Search gaming center...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCenters.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerHomePage(),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  filteredCenters[index],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<bool> isUserClient() async {
  // Implement logic to check if user is a client (e.g., Firebase authentication)
  return true; // Placeholder: Replace with actual logic
}

List<String> getGamingCentersFromClients() {
  // Fetch gaming center names added by clients
  return [
    'Elite Gaming Arena',
    'Pro Gamers Hub',
    'CyberX Gaming',
    'Gamer’s Paradise'
  ];
}
