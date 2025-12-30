import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/event_state.dart';

import 'ai_screen.dart';
import 'ai_context.dart';

class AiFloatingButton extends StatelessWidget {
  const AiFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_fab',
      child: const Icon(Icons.smart_toy_outlined),
      onPressed: () {
        final appState = context.read<AppState>();
        final eventState = context.read<EventState>();

        final aiContext = AiContext(
          city: appState.cityLabel,
          events: eventState.eventsForCity(appState.cityLabel.split(',').first),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AiScreen(contextData: aiContext)),
        );
      },
    );
  }
}
