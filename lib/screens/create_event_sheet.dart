import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/event_state.dart';
import '../state/app_state.dart';
import '../services/error_handler.dart';

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

  bool _creating = false;

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
    final appState = context.read<AppState>();
    final user = FirebaseAuth.instance.currentUser;

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
            const Text(
              "Create Event",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // TITLE
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Event Title'),
            ),
            const SizedBox(height: 12),

            // DESCRIPTION
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // LOCATION
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
                  child: const Text('Select Date'),
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
                  child: const Text('Select Time'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _creating
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        final description = _descriptionController.text.trim();
                        final location = _locationController.text.trim();

                        if (title.isEmpty) {
                          UiHelpers.showPremiumSnackBar(context, message: "Please enter the event title.");
                          return;
                        }
                        if (description.isEmpty) {
                          UiHelpers.showPremiumSnackBar(context, message: "Please enter the event description.");
                          return;
                        }
                        if (location.isEmpty) {
                          UiHelpers.showPremiumSnackBar(context, message: "Please enter the event location.");
                          return;
                        }

                        if (user == null || appState.cityId == null) {
                          UiHelpers.showPremiumSnackBar(context, message: "City or user session not found.");
                          return;
                        }

                        setState(() => _creating = true);

                        final dateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );

                        try {
                          await eventState.addEvent(
                            cityId: appState.cityId!,
                            title: title,
                            description: description,
                            location: location,
                            dateTime: dateTime,
                            creatorId: user.uid,
                            creatorName: user.displayName ?? user.email ?? "User",
                          );

                          if (mounted) {
                            UiHelpers.showPremiumSnackBar(
                              context,
                              message: "Event successfully created! 🎉",
                              isError: false,
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          setState(() => _creating = false);
                          if (mounted) {
                            final friendlyMsg = ErrorMapper.getFriendlyMessage(e);
                            UiHelpers.showPremiumSnackBar(context, message: friendlyMsg, isError: true);
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
