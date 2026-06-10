import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:flutter/foundation.dart';

/// Service class to handle system volume control operations.
/// This abstraction provides a clean interface for volume management.
class VolumeService {
  static final VolumeService _instance = VolumeService._internal();
  bool _initialized = false;

  factory VolumeService() {
    return _instance;
  }

  VolumeService._internal();

  /// Initialize the volume service.
  /// This must be called before any other methods.
  Future<void> initialize() async {
    if (!_initialized) {
      try {
        //await PerfectVolumeControl.init();
        _initialized = true;
        debugPrint('VolumeService initialized successfully');
      } catch (e) {
        debugPrint('Error initializing VolumeService: $e');
        rethrow;
      }
    }
  }

  /// Get the current system media volume (0.0 to 1.0).
  Future<double> getCurrentVolume() async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final volume = await PerfectVolumeControl.getVolume();
      debugPrint('Current volume: $volume');
      return volume;
    } catch (e) {
      debugPrint('Error getting current volume: $e');
      return 0.5; // Return default if error
    }
  }

  /// Set the system media volume to the specified value (0.0 to 1.0).
  ///
  /// [volume] should be a value between 0.0 (mute) and 1.0 (max volume).
  Future<void> setVolume(double volume) async {
    if (!_initialized) {
      await initialize();
    }

    // Clamp volume to valid range
    final clampedVolume = volume.clamp(0.0, 1.0);

    try {
      await PerfectVolumeControl.setVolume(clampedVolume);
      debugPrint('Volume set to: $clampedVolume');
    } catch (e) {
      debugPrint('Error setting volume: $e');
      rethrow;
    }
  }

  /// Increase volume by a specific percentage (0.0 to 1.0).
  Future<void> increaseVolume({double step = 0.1}) async {
    final currentVolume = await getCurrentVolume();
    final newVolume = (currentVolume + step).clamp(0.0, 1.0);
    await setVolume(newVolume);
  }

  /// Decrease volume by a specific percentage (0.0 to 1.0).
  Future<void> decreaseVolume({double step = 0.1}) async {
    final currentVolume = await getCurrentVolume();
    final newVolume = (currentVolume - step).clamp(0.0, 1.0);
    await setVolume(newVolume);
  }

  /// Mute the system media volume.
  Future<void> mute() async {
    await setVolume(0.0);
  }

  /// Unmute to a reasonable default volume (50%).
  Future<void> unmute() async {
    await setVolume(0.5);
  }
}
