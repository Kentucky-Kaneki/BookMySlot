import 'package:book_my_slot/customer_screens/center_details_page.dart';
import 'package:flutter/material.dart';
import 'package:book_my_slot/constants.dart';
import 'package:book_my_slot/custom_widgets.dart';

class YourBookings extends StatelessWidget {
  const YourBookings({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Slots'),
        backgroundColor: kMainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Booking Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // TODO: fetch data from supabase

            // _buildDetailRow('Gaming Center:', gamingCenter),
            // _buildDetailRow('Game:', game),
            // _buildDetailRow('Slot:', slot),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CustomerHomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
