import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:mobile_flutter/domain/entities/epidemic_zone.dart';

class ZoneAlertAudioService {
  ZoneAlertAudioService._();

  static final ZoneAlertAudioService instance = ZoneAlertAudioService._();

  ZoneRiskLevel? _lastRiskLevel;
  DateTime? _lastAnnouncedAt;
  int _lastZoneCount = 0;
  bool _isPlaying = false;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  Future<void> announceHighestRisk({
    required ZoneRiskLevel highestRisk,
    required int zoneCount,
    Duration minInterval = const Duration(seconds: 20),
  }) async {
    final now = DateTime.now();

    final hasRiskChanged = _lastRiskLevel != highestRisk;
    final hasCountChanged = _lastZoneCount != zoneCount;
    final beyondInterval = _lastAnnouncedAt == null ||
        now.difference(_lastAnnouncedAt!) >= minInterval;

    if (!hasRiskChanged && !hasCountChanged && !beyondInterval) {
      return;
    }

    if (_isPlaying) return;

    _lastRiskLevel = highestRisk;
    _lastZoneCount = zoneCount;
    _lastAnnouncedAt = now;

    _isPlaying = true;
    try {
      await _playDangerAlertTone(highestRisk);
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _ringtonePlayer.stop();
  }

  Future<void> _playDangerAlertTone(ZoneRiskLevel highestRisk) async {
    // Prefer alarm channel for stronger/louder warning perception.
    try {
      await _ringtonePlayer.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        asAlarm: true,
        volume: 1,
        looping: true,
      );

      final ringDuration = switch (highestRisk) {
        ZoneRiskLevel.low => const Duration(milliseconds: 1200),
        ZoneRiskLevel.medium => const Duration(milliseconds: 1800),
        ZoneRiskLevel.high => const Duration(milliseconds: 2400),
        ZoneRiskLevel.critical => const Duration(milliseconds: 3200),
      };

      await Future<void>.delayed(ringDuration);
      await _ringtonePlayer.stop();
      return;
    } catch (_) {
      // Fallback if alarm channel isn't available on the platform/device.
    }

    // Fallback: alert beep loop.
    final repeat = switch (highestRisk) {
      ZoneRiskLevel.low => 1,
      ZoneRiskLevel.medium => 2,
      ZoneRiskLevel.high => 3,
      ZoneRiskLevel.critical => 4,
    };

    for (var i = 0; i < repeat; i++) {
      if (!_isPlaying) return;
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
  }
}
