import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/palette.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatelessWidget {
  final AudioManager audio;
  const SettingsScreen({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      backgroundColor: Palette.wine,
      appBar: AppBar(
        backgroundColor: Palette.wine,
        elevation: 0,
        foregroundColor: Palette.cream,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound',
                        style: TextStyle(color: Palette.cream)),
                    value: settings.sound,
                    activeColor: Palette.gold,
                    onChanged: (v) {
                      settings.setSound(v);
                      if (v) {
                        audio.startMusic();
                      } else {
                        audio.stopMusic();
                      }
                    },
                  ),
                  const Divider(color: Palette.line, height: 1),
                  SwitchListTile(
                    title: const Text('Haptics',
                        style: TextStyle(color: Palette.cream)),
                    value: settings.haptics,
                    activeColor: Palette.gold,
                    onChanged: settings.setHaptics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to play',
                        style: TextStyle(
                            color: Palette.cream,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
                    Text(
                      'Fill the white cells with digits 1 to 9. Each '
                      'unbroken horizontal or vertical stretch of white '
                      'cells is a "run" — a black cell just before it shows '
                      'the sum that run must add up to.\n\n'
                      'No digit may repeat within a single run, even though '
                      'the same digit can appear in a crossing run.\n\n'
                      'Tap a white cell to select it, then tap a digit '
                      'below. Duplicate digits within the same run are '
                      'flagged in red.\n\n'
                      'Every puzzle has exactly one valid filling, reachable '
                      'by pure deduction.',
                      style: TextStyle(
                          color: Palette.haze, fontSize: 13.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _card(
              child: ListTile(
                title: const Text('Reset all progress',
                    style: TextStyle(color: Palette.coral)),
                trailing:
                    const Icon(Icons.delete_outline, color: Palette.coral),
                onTap: () => _confirmReset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.line),
        ),
        child: child,
      );

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Palette.panel,
        title: const Text('Reset progress?',
            style: TextStyle(color: Palette.cream)),
        content: const Text('This clears all stars and solved levels.',
            style: TextStyle(color: Palette.haze)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Palette.haze)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProgressService>().reset();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Palette.coral)),
          ),
        ],
      ),
    );
  }
}
