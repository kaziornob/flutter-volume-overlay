import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'volume_service.dart';

/// Entry point for the overlay window.
/// This function is called when the overlay is initialized.
void overlayEntryPoint() {
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const VolumeControlOverlay(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

class VolumeControlOverlay extends StatefulWidget {
  const VolumeControlOverlay({Key? key}) : super(key: key);

  @override
  State<VolumeControlOverlay> createState() => _VolumeControlOverlayState();
}

class _VolumeControlOverlayState extends State<VolumeControlOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late VolumeService _volumeService;
  double _currentVolume = 0.5;
  bool _isInitialized = false;
  static const int _autoCloseDuration = 4; // seconds

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  /// Initialize the overlay with animation and auto-close timer.
  Future<void> _initializeOverlay() async {
    try {
      _volumeService = VolumeService();
      await _volumeService.initialize();

      // Initialize current volume
      _currentVolume = await _volumeService.getCurrentVolume();

      // Setup fade animation controller
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
      );

      setState(() {
        _isInitialized = true;
      });

      // Start auto-close timer
      _startAutoCloseTimer();
    } catch (e) {
      debugPrint('Error initializing overlay: $e');
    }
  }

  /// Start the timer to auto-close the overlay after [_autoCloseDuration] seconds.
  void _startAutoCloseTimer() {
    Future.delayed(Duration(seconds: _autoCloseDuration), () {
      if (mounted) {
        _closeOverlay();
      }
    });
  }

  /// Close the overlay with fade-out animation.
  Future<void> _closeOverlay() async {
    try {
      // Trigger fade-out animation
      await _fadeController.forward();

      // Close the overlay window
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }

  /// Handle volume slider changes.
  Future<void> _onVolumeChanged(double newVolume) async {
    setState(() {
      _currentVolume = newVolume;
    });

    try {
      await _volumeService.setVolume(newVolume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.expand(
        child: SizedBox.shrink(),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.grey.shade900.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Volume Control',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Volume slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: _currentVolume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.grey.shade700,
                    onChanged: _onVolumeChanged,
                  ),
                ),

                // Volume percentage display
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${(_currentVolume * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                  ),
                ),

                // Auto-close indicator
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Closes in $_autoCloseDuration seconds',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
