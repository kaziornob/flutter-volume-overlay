import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'overlay_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  await _initializeOverlay();
  runApp(const VolumeOverlayApp());
}

/// Request necessary permissions for system overlay and volume control.
Future<void> _requestPermissions() async {
  final status = await Permission.systemAlertWindow.request();
  
  if (status.isDenied) {
    debugPrint('System alert window permission denied');
  } else if (status.isPermanentlyDenied) {
    debugPrint('System alert window permission permanently denied. Opening app settings.');
    openAppSettings();
  } else if (status.isGranted) {
    debugPrint('System alert window permission granted');
  }
}

/// Initialize the overlay window configuration.
Future<void> _initializeOverlay() async {
  try {
    await FlutterOverlayWindow.overlayPutMethod(
      overlayEntryPoint,
      isNotificationPanel: false,
    );
    debugPrint('Overlay initialized successfully');
  } catch (e) {
    debugPrint('Error initializing overlay: $e');
  }
}

class VolumeOverlayApp extends StatelessWidget {
  const VolumeOverlayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volume Overlay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const TransparentHome(),
    );
  }
}

/// Transparent home screen that immediately triggers overlay and closes.
class TransparentHome extends StatefulWidget {
  const TransparentHome({Key? key}) : super(key: key);

  @override
  State<TransparentHome> createState() => _TransparentHomeState();
}

class _TransparentHomeState extends State<TransparentHome> {
  @override
  void initState() {
    super.initState();
    _launchOverlayAndClose();
  }

  /// Launch the overlay window and then close/minimize the main app.
  Future<void> _launchOverlayAndClose() async {
    try {
      // Check if overlay permissions are granted
      final status = await Permission.systemAlertWindow.status;
      
      if (status.isGranted) {
        // Show the overlay
        await FlutterOverlayWindow.showOverlay(
          height: 80,
          width: 300,
          alignment: Alignment.topCenter,
          margin: const EdgeInsets.only(top: 50),
        );
        debugPrint('Overlay shown successfully');
      } else {
        debugPrint('Overlay permission not granted. Requesting...');
        await _requestPermissions();
      }

      // Close the main app after a short delay to ensure overlay is visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Minimize or close the main app
      if (mounted) {
        // Pop the current route or minimize the app
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error launching overlay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        // Completely transparent screen
      ),
    );
  }
}
