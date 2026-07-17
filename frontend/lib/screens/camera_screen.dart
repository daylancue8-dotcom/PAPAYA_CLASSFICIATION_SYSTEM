import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../classifier/papaya_classifier.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController?       _cameraController;
  List<CameraDescription> _cameras = [];
  final PapayaClassifier  _classifier = PapayaClassifier();

  bool _isInitialized = false;
  bool _isProcessing  = false;
  bool _isFlashOn     = false;
  int  _selectedCameraIndex = 0;
  static const double _minConfidence = 0.75;

  ClassificationResult? _liveResult;
  bool _isLiveMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    await _classifier.initialize();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      await _setupCamera(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isInitialized    = true;
      });
      // Start live after camera ready
      if (_isLiveMode) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _runLiveDetection();
        });
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  // ── LIVE DETECTION ────────────────────────────────────────
  // Simple timer approach — captures photo every 1.5 seconds
  // NO image stream — avoids hanging
  Future<void> _runLiveDetection() async {
    if (!mounted)           return;
    if (!_isLiveMode)       return;
    if (_isProcessing)      return;
    if (_cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final XFile     photo      = await _cameraController!.takePicture();
      final Uint8List imageBytes = await photo.readAsBytes();
      final result               = await _classifier.classifyImage(imageBytes);

      if (result != null && mounted) {
        if (result.confidence >= _minConfidence) {
          setState(() => _liveResult = result);
        } else {
          setState(() => _liveResult = null);
        }
      }
    } catch (e) {
      debugPrint('Live detection error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Schedule next detection
        if (_isLiveMode) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _isLiveMode) _runLiveDetection();
          });
        }
      }
    }
  }

  // ── TOGGLE LIVE / MANUAL ──────────────────────────────────
  void _toggleLiveMode() {
    setState(() {
      _isLiveMode   = !_isLiveMode;
      _liveResult   = null;
      _isProcessing = false;
    });
    if (_isLiveMode) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _runLiveDetection();
      });
    }
  }

  // ── CAPTURE TO RESULT SCREEN ─────────────────────────────
  Future<void> _captureAndClassify() async {
    if (_isProcessing)      return;
    if (_cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    final wasLive = _isLiveMode;
    setState(() {
      _isLiveMode   = false;
      _isProcessing = true;
    });

    try {
      final XFile     photo      = await _cameraController!.takePicture();
      final Uint8List imageBytes = await photo.readAsBytes();
      final result               = await _classifier.classifyImage(imageBytes);

      if (result != null && mounted) {
        if (result.confidence >= _minConfidence) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(imageBytes: imageBytes, result: result),
            ),
          );
          if (mounted && wasLive) {
            setState(() => _isLiveMode = true);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _runLiveDetection();
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Low confidence detected. This does not appear to be a papaya.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final wasLive = _isLiveMode;
    setState(() {
      _isLiveMode    = false;
      _isInitialized = false;
      _liveResult    = null;
      _isProcessing  = false;
    });
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _cameraController?.dispose();
    _cameraController = null;
    if (wasLive && mounted) setState(() => _isLiveMode = true);
    await _setupCamera(_cameras[_selectedCameraIndex]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      setState(() { _isLiveMode = false; _isProcessing = false; });
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isLiveMode = true);
      _setupCamera(_cameras[_selectedCameraIndex]);
    }
  }

  @override
  void dispose() {
    _isLiveMode   = false;
    _isProcessing = false;
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _classifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CameraButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isLiveMode
                          ? const Color(0xFF4CAF50).withOpacity(0.85)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLiveMode)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _isLiveMode ? 'LIVE' : 'MANUAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CameraButton(
                    icon: _isFlashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onTap: _toggleFlash,
                    isActive: _isFlashOn,
                  ),
                ],
              ),
            ),
          ),

          // Scanning frame
          Center(
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _liveResult != null
                      ? _liveResult!.labelColor
                      : const Color(0xFF4CAF50),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                _CornerBorder(top: true,  left: true),
                _CornerBorder(top: true,  left: false),
                _CornerBorder(top: false, left: true),
                _CornerBorder(top: false, left: false),
              ]),
            ),
          ),

          // Scanning indicator
          if (_isProcessing && _liveResult == null)
            const Center(
              child: SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ),

          // Live result card
          if (_liveResult != null)
            Positioned(
              bottom: 170, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _liveResult!.labelColor.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(_liveResult!.emoji,
                            style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _liveResult!.displayLabel.toUpperCase(),
                                style: TextStyle(
                                  color: _liveResult!.labelColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Confidence: ${_liveResult!.confidencePercent}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isProcessing)
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._liveResult!.allProbabilities.entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(e.key,
                                  style: TextStyle(
                                    color: e.key == _liveResult!.label
                                        ? _liveResult!.labelColor
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: e.key == _liveResult!.label
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: e.value,
                                    minHeight: 6,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation(
                                      e.key == _liveResult!.label
                                          ? _liveResult!.labelColor
                                          : Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(e.value * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: e.key == _liveResult!.label
                                      ? _liveResult!.labelColor
                                      : Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Hint
          if (_liveResult == null && !_isProcessing)
            Positioned(
              bottom: 200, left: 0, right: 0,
              child: Text(
                'Point camera at a papaya',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CameraButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: _switchCamera,
                    size: 48,
                  ),
                  GestureDetector(
                    onTap: _captureAndClassify,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing ? Colors.grey : const Color(0xFF4CAF50),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 32),
                    ),
                  ),
                  _CameraButton(
                    icon: _isLiveMode
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onTap: _toggleLiveMode,
                    size: 48,
                    isActive: _isLiveMode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double size;

  const _CameraButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

class _CornerBorder extends StatelessWidget {
  final bool top;
  final bool left;

  const _CornerBorder({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    top  ? 0 : null,
      bottom: top  ? null : 0,
      left:   left ? 0 : null,
      right:  left ? null : 0,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border(
            top:    top  ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            left:   left ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            right: !left ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}