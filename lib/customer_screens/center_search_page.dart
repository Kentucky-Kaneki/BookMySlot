import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_my_slot/constants.dart';
import 'center_details_page.dart';

class CenterSearchPage extends StatefulWidget {
  const CenterSearchPage({super.key});

  @override
  _CenterSearchPageState createState() => _CenterSearchPageState();
}

class _CenterSearchPageState extends State<CenterSearchPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> gamingCenters = [];
  List<Map<String, dynamic>> filteredCenters = [];

  @override
  void initState() {
    super.initState();
    _loadGamingCenters();
  }

  Future<void> _loadGamingCenters() async {
    final response = await supabase.from('gaming_center').select('id, name');

    setState(() {
      gamingCenters = List<Map<String, dynamic>>.from(response);
      filteredCenters = gamingCenters;
    });
  }

  void _filterCenters(String query) {
    setState(() {
      filteredCenters = gamingCenters
          .where((center) =>
              center['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
                  final center = filteredCenters[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CenterDetailsPage(centerId: center['id']),
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
                        child: Text(
                          center['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
  }
}
