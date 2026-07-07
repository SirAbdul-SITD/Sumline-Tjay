import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/palette.dart';
import 'services/puzzle_repository.dart';
import 'services/progress_service.dart';
import 'services/settings_service.dart';
import 'services/audio_manager.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SumlineApp());
}

class SumlineApp extends StatefulWidget {
  const SumlineApp({super.key});

  @override
  State<SumlineApp> createState() => _SumlineAppState();
}

class _SumlineAppState extends State<SumlineApp> {
  final repo = PuzzleRepository();
  final progress = ProgressService();
  final settings = SettingsService();
  late final AudioManager audio;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    audio = AudioManager(settings);
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([repo.load(), progress.init(), settings.init()]);
    if (settings.sound) audio.startMusic();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: MaterialApp(
        title: 'Sumline',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Palette.wine,
          colorScheme: const ColorScheme.dark(
            primary: Palette.gold,
            surface: Palette.panel,
          ),
        ),
        home: _ready
            ? HomeScreen(repo: repo, audio: audio)
            : const _SplashScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Palette.wine,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calculate_outlined, color: Palette.gold, size: 56),
            SizedBox(height: 16),
            Text('SUMLINE',
                style: TextStyle(
                    color: Palette.cream,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
