import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

enum AISpeakerState { aiSpeaking, userSpeaking, idle }

class AiSpeakingView extends StatefulWidget {
  const AiSpeakingView(this.call, {required this.boxConstraints, super.key});

  final Call call;
  final BoxConstraints boxConstraints;

  @override
  State<AiSpeakingView> createState() => _AiSpeakingViewState();
}

class _AiSpeakingViewState extends State<AiSpeakingView>
    with TickerProviderStateMixin {
  static const _agentId = "lucy";
  var _speakerState = AISpeakerState.idle;
  var _currentAmplitude = 0.0;
  late AnimationController _timeController;
  late AnimationController _amplitudeController;

  late StreamSubscription<CallState> _callStateSubscription;

  @override
  void initState() {
    super.initState();
    _timeController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
      setState(() {
        // The state that has changed here is the animation object's value.
      });
    });
    _timeController.repeat();
    _amplitudeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: 0.0,
      upperBound: _currentAmplitude,
    );

    _updateSpeakerState(widget.call.state.value);
    _listenToCallState();
  }

  @override
  void didUpdateWidget(covariant AiSpeakingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.call != widget.call) {
      _callStateSubscription.cancel();
      _listenToCallState();
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _amplitudeController.dispose();
    _callStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(
      widget.boxConstraints.maxWidth,
      widget.boxConstraints.maxHeight,
    );

    final time = _timeController.value;
    final amplitude = _amplitudeController.value;

    return Stack(
      children: [
        GlowLayer(
          baseRadiusMax: 1,
          baseRadiusMin: 3 / 5,
          baseOpacity: 0.35,
          scaleRange: 0.3,
          waveRangeMin: 0.2,
          waveRangeMax: 0.02,
          amplitude: amplitude,
          time: time,
          size: size,
          speakerState: _speakerState,
        ),
        GlowLayer(
          baseRadiusMax: 3 / 5,
          baseRadiusMin: 2 / 5,
          baseOpacity: 0.35,
          scaleRange: 0.3,
          waveRangeMin: 0.15,
          waveRangeMax: 0.03,
          amplitude: amplitude,
          time: time,
          size: size,
          speakerState: _speakerState,
        ),
        GlowLayer(
          baseRadiusMax: 1 / 5,
          baseRadiusMin: 2 / 5,
          baseOpacity: 0.9,
          scaleRange: 0.5,
          waveRangeMin: 0.35,
          waveRangeMax: 0.05,
          amplitude: amplitude,
          time: time,
          size: size,
          speakerState: _speakerState,
        ),
      ],
    );
  }

  void _listenToCallState() {
    _callStateSubscription = widget.call.state.asStream().listen((callState) {
      _updateSpeakerState(callState);
    });
  }

  void _updateSpeakerState(CallState callState) {
    final activeSpeakers = callState.activeSpeakers;
    final agent = activeSpeakers.firstWhereOrNull(
      (p) => p.userId.contains(_agentId),
    );
    final user = activeSpeakers.firstWhereOrNull(
      (p) => p.userId == callState.localParticipant?.userId,
    );

    List<double> audioLevels;

    if (agent != null && agent.isSpeaking) {
      _speakerState = AISpeakerState.aiSpeaking;
      audioLevels =
          agent.audioLevels
              .map((e) => e / (math.Random().nextInt(2) + 1))
              .toList();
    } else if (user != null && user.isSpeaking) {
      _speakerState = AISpeakerState.userSpeaking;
      audioLevels = user.audioLevels;
    } else {
      _speakerState = AISpeakerState.idle;
      audioLevels = [];
    }
    final amplitude = _computeSingleAmplitude(audioLevels);
    _updateAmplitudeAnimation(amplitude);
  }

  double _computeSingleAmplitude(List<double> audioLevels) {
    final normalized = _normalizePeak(audioLevels);
    if (normalized.isEmpty) return 0;

    final sum = normalized.reduce((value, element) => value + element);
    final average = sum / normalized.length;
    return average;
  }

  List<double> _normalizePeak(List<double> audioLevels) {
    final max = audioLevels.fold(
      0.0,
      (value, element) => math.max(value, element),
    );
    if (max == 0.0) return audioLevels;

    return audioLevels.map((e) => e / max).toList();
  }

  void _updateAmplitudeAnimation(double newAmplitude) {
    if (_currentAmplitude != newAmplitude) {
      var currentAnimationState = _amplitudeController.value;

      _amplitudeController.dispose();
      final reverse = currentAnimationState > newAmplitude;

      _amplitudeController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
        lowerBound: reverse ? newAmplitude : currentAnimationState,
        upperBound: reverse ? currentAnimationState : newAmplitude,
      );

      _amplitudeController.addListener(() {
        setState(() {
          // The state that has changed here is the animation object's value.
        });
      });

      if (currentAnimationState != newAmplitude) {
        if (reverse) {
          _amplitudeController.reverse(from: currentAnimationState);
        } else {
          _amplitudeController.forward();
        }
      }
    }

    _currentAmplitude = newAmplitude;
  }
}

class GlowLayer extends StatelessWidget {
  const GlowLayer({
    required this.speakerState,
    required this.baseRadiusMin,
    required this.baseRadiusMax,
    required this.baseOpacity,
    required this.scaleRange,
    required this.waveRangeMin,
    required this.waveRangeMax,
    required this.amplitude,
    required this.time,
    required this.size,
    super.key,
  });

  final AISpeakerState speakerState;
  final double baseRadiusMin;
  final double baseRadiusMax;
  final double baseOpacity;
  final double scaleRange;
  final double waveRangeMin;
  final double waveRangeMax;
  final double amplitude;
  final double time;
  final Size size;

  @override
  Widget build(BuildContext context) {
    // The actual radius = lerp from min->max based on amplitude
    final baseRadius = lerpDouble(baseRadiusMin, baseRadiusMax, amplitude)!;

    // The waveRange also “lerps,” but we want big wave at low amplitude => waveRangeMin at amplitude=1
    // => just invert the parameter. Another approach: waveRange = waveRangeMax + (waveRangeMin-waveRangeMax)*(1 - amplitude).
    final waveRange = lerpDouble(waveRangeMax, waveRangeMin, (1 - amplitude))!;

    final radius = baseRadius * math.min(size.width, size.height);

    // Subtle elliptical warping from sin/cos
    final shapeWaveSin = math.sin(2 * math.pi * time);
    final shapeWaveCos = math.cos(2 * math.pi * time);

    // scale from amplitude
    final amplitudeScale = 1.0 + scaleRange * amplitude;

    // final x/y scale => merges amplitude + wave
    final xScale = amplitudeScale + waveRange * shapeWaveSin;
    final yScale = amplitudeScale + waveRange * shapeWaveCos;

    return Center(
      child: Opacity(
        opacity: baseOpacity,
        child: Transform.scale(
          scaleY: yScale,
          scaleX: xScale,
          child: SizedBox(
            height: radius,
            width: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.5,
                  colors: speakerState.gradientColors,
                  stops: <double>[0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on AISpeakerState {
  List<Color> get gradientColors => switch (this) {
    AISpeakerState.userSpeaking => [Colors.red, Colors.red.withAlpha(0)],
    _ => [
      Color.from(red: 0.0, green: 0.976, blue: 1.0, alpha: 1.0),
      Color.from(red: 0.0, green: 0.227, blue: 1.0, alpha: 0.0),
    ],
  };
}
