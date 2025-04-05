import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:book_my_slot/constants.dart';

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

class CustomerSlotSelectionPage extends StatefulWidget {
  final String gamingCenter;
  final String game;

  const CustomerSlotSelectionPage(
      {super.key, required this.gamingCenter, required this.game});

  @override
  _CustomerSlotSelectionPageState createState() =>
      _CustomerSlotSelectionPageState();
}

class _CustomerSlotSelectionPageState extends State<CustomerSlotSelectionPage> {
  List<String> availableSlots = [];
  dynamic selectedSlot;

  @override
  void initState() {
    super.initState();
    _fetchAvailableSlots();
  }

  Future<void> _fetchAvailableSlots() async {
    final response = await Supabase.instance.client
        .from('slots')
        .select('id')
        .eq('gaming_center', widget.gamingCenter)
        .eq('game', widget.game)
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gamingCenter} - ${widget.game}'),
        backgroundColor: kMainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Slot:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _bookSlot,
                style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
                child: const Text('Book Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
