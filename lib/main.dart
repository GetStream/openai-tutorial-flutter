import 'package:flutter/material.dart';

import 'ai_demo_controller.dart';
import 'home_page.dart';

void main() {
  final aiController = AiDemoController();
  runApp(AIVideoDemoApp(aiController));
}

class AIVideoDemoApp extends StatelessWidget {
  const AIVideoDemoApp(this.aiDemoController, {super.key});

  final AiDemoController aiDemoController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Video Demo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(aiDemoController),
    );
  }
}
