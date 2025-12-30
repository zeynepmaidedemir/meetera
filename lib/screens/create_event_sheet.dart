import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/event_state.dart';

class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key});

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventState = context.read<EventState>();
    final userId = 'me';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event title'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),

            // DATE
            Row(
              children: [
                Expanded(
                  child: Text(
                    '📅 ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: const Text('Select date'),
                ),
              ],
            ),

            // TIME
            Row(
              children: [
                Expanded(child: Text('🕒 ${_selectedTime.format(context)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                  child: const Text('Select time'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final description = _descriptionController.text.trim();
                final location = _locationController.text.trim();

                if (title.isEmpty || description.isEmpty) return;

                final dateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                );

                eventState.addEvent(
                  title: title,
                  description: description,
                  location: location,
                  dateTime: dateTime,
                  creatorId: userId,
                );

                Navigator.pop(context);
              },
              child: const Text('Create event'),
            ),
          ],
        ),
      ),
    );
  }
}
