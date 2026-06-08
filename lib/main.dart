import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'game/space_invaders_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SpaceInvadersApp());
}

class SpaceInvadersApp extends StatelessWidget {
  const SpaceInvadersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Invaders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SpaceInvadersGame _game = SpaceInvadersGame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Game widget with drag movement
          GestureDetector(
            onPanUpdate: (details) {
              _game.onExternalPanUpdate(details.delta.dx);
            },
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                _game.onExternalTapAt(
                  Vector2(localPos.dx, localPos.dy),
                );
              }
            },
            child: GameWidget(
              game: _game,
            ),
          ),

          // Fire button overlay (bottom-right, uses Listener to avoid pan gesture conflicts)
          Positioned(
            right: 20,
            bottom: 20,
            child: Listener(
              onPointerDown: (_) {
                _game.onExternalFireTap();
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FF4444),
                  border: Border.all(
                    color: const Color(0x66FF4444),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x33FF4444),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xAAFF4444),
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
