import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' as stream_video;

import 'ai_demo_controller.dart';
import 'ai_speaking_view.dart';

class HomePage extends StatelessWidget {
  const HomePage(this.controller, {super.key});

  final AiDemoController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder:
              (context, constraints) => ListenableBuilder(
                listenable: controller,
                builder:
                    (context, _) => switch (controller.callState) {
                      AICallState.idle => GestureDetector(
                        onTap: controller.joinCall,
                        child: Center(child: Text('Click to talk to AI')),
                      ),
                      AICallState.joining => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Waiting for AI agent to join...'),
                            SizedBox(height: 8),
                            CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      AICallState.active => Stack(
                        children: [
                          AiSpeakingView(
                            controller.call!,
                            boxConstraints: constraints,
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: stream_video.LeaveCallOption(
                                  call: controller.call!,
                                  onLeaveCallTap: controller.leaveCall,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    },
              ),
        ),
      ),
    );
  }
}
