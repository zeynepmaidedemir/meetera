import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/event_state.dart';
import '../state/app_state.dart';

const mockEventImages = [
  'https://images.unsplash.com/photo-1515169067865-5387ec356754',
  'https://images.unsplash.com/photo-1508609349937-5ec4ae374ebf',
  'https://images.unsplash.com/photo-1528605248644-14dd04022da1',
  'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
];

class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedImage;

  @override
  Widget build(BuildContext context) {
    final city = context.read<AppState>().cityLabel.split(',').first;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Create Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
            ),

            const SizedBox(height: 12),

            // 🖼️ MOCK IMAGE PICKER
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mockEventImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = mockEventImages[i];
                  final selected = selectedImage == url;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = selected ? null : url;
                      });
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (selected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      selectedDate = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : selectedDate!.toString().split(' ')[0],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      setState(() {});
                    },
                    child: Text(
                      selectedTime == null
                          ? 'Select Time'
                          : selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (titleCtrl.text.isEmpty ||
                      descCtrl.text.isEmpty ||
                      locationCtrl.text.isEmpty ||
                      selectedDate == null ||
                      selectedTime == null)
                    return;

                  final dateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  context.read<EventState>().createEvent(
                    city: city,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    dateTime: dateTime,
                    creatorId: 'me',
                    creatorName: 'You',
                    imageUrl: selectedImage,
                  );

                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
