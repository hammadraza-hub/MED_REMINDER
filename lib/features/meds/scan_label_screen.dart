import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/ocr_service.dart';
import 'review_scan_screen.dart';
import 'add_manual_screen.dart';

class ScanLabelScreen extends StatefulWidget {
  const ScanLabelScreen({super.key});

  @override
  State<ScanLabelScreen> createState() => _ScanLabelScreenState();
}

class _ScanLabelScreenState extends State<ScanLabelScreen> {
  final CameraService _camera = CameraService();
  final OcrService _ocr = OcrService();

  bool _cameraReady = false;
  bool _cameraFailed = false;
  bool _isCapturing = false;
  bool _isProcessing = false;

  // ============================================================
  // LIVE SCANNER STATE
  // ============================================================

  bool _medicineInFrame = false;
  bool _liveFrameBusy = false;
  DateTime? _lastLiveScan;

  XFile? _capturedPhoto;

  List<DetectedMedicine> _detectedMedicines = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final bool ok = await _camera.initialize();

    if (!mounted) return;

    setState(() {
      _cameraReady = ok;
      _cameraFailed = !ok;
    });

    if (ok) {
      await _startLiveDetection();
    }
  }

  // ============================================================
  // LIVE MEDICINE / PRESCRIPTION DETECTION
  // ============================================================

  Future<void> _startLiveDetection() async {
    if (!_cameraReady) return;
    if (_capturedPhoto != null) return;
    if (_isCapturing || _isProcessing) return;

    try {
      await _camera.startImageStream((CameraImage image) async {
        if (!mounted ||
            _capturedPhoto != null ||
            _isCapturing ||
            _isProcessing ||
            _liveFrameBusy) {
          return;
        }

        final DateTime now = DateTime.now();

        // Run OCR approximately every 900ms instead of every frame.
        if (_lastLiveScan != null &&
            now.difference(_lastLiveScan!).inMilliseconds < 900) {
          return;
        }

        _lastLiveScan = now;
        _liveFrameBusy = true;

        try {
          final CameraController? controller = _camera.controller;

          if (controller == null || !controller.value.isInitialized) {
            return;
          }

          final String text = await _ocr.readCameraFrame(
            image: image,
            sensorOrientation: _camera.sensorOrientation,
            lensDirection: _camera.lensDirection,
            deviceOrientation: controller.value.deviceOrientation,
          );

          if (!mounted || _capturedPhoto != null) return;

          final bool relevant = _looksLikeMedicineOrPrescription(text);

          if (relevant != _medicineInFrame) {
            setState(() {
              _medicineInFrame = relevant;
            });
          }
        } catch (e) {
          debugPrint('Live detection error: $e');
        } finally {
          _liveFrameBusy = false;
        }
      });
    } catch (e) {
      // This can occur if the stream is already active.
      // It should not break the scanner UI.
      debugPrint('Could not start live detection: $e');
    }
  }

  // ============================================================
  // SMART FRAME HEURISTIC
  // ============================================================

  bool _looksLikeMedicineOrPrescription(String text) {
    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      return false;
    }

    final String lower = cleanText.toLowerCase();

    // ----------------------------------------------------------
    // Strong evidence: medicine strength
    //
    // Examples:
    // 500 mg
    // 0.5 mg
    // 100 mcg
    // 5 ml
    // 1000 IU
    // 250 mg/5ml
    // ----------------------------------------------------------

    final bool hasStrength = RegExp(
      r'\b\d+(?:[.,]\d+)?\s*'
      r'(mg|mcg|µg|ug|g|ml|iu|units?)\b',
      caseSensitive: false,
    ).hasMatch(lower);

    if (hasStrength) {
      return true;
    }

    // ----------------------------------------------------------
    // Dosage forms / medicine packaging words
    // ----------------------------------------------------------

    final bool hasDosageForm = RegExp(
      r'\b('
      r'tablet|tablets|tab|tabs|'
      r'capsule|capsules|cap|caps|'
      r'syrup|suspension|solution|'
      r'drops|cream|ointment|'
      r'injection|injectable|'
      r'inhaler|patch|spray'
      r')\b',
      caseSensitive: false,
    ).hasMatch(lower);

    if (hasDosageForm) {
      return true;
    }

    // ----------------------------------------------------------
    // Prescription-related terms
    // ----------------------------------------------------------

    final bool hasPrescriptionTerms = RegExp(
      r'\b('
      r'rx|prescription|prescribed|'
      r'dosage|dose|medicine|medication|'
      r'patient|doctor|physician|pharmacy|'
      r'take|daily|twice|once|'
      r'bid|bd|tid|tds|qid|qhs'
      r')\b',
      caseSensitive: false,
    ).hasMatch(lower);

    // Count useful OCR lines.
    final int textLines = cleanText
        .split(RegExp(r'[\r\n]+'))
        .where((line) => line.trim().length >= 3)
        .length;

    // Prescription/document should contain some structure,
    // not just one random matching word.
    if (hasPrescriptionTerms && textLines >= 3) {
      return true;
    }

    return false;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _camera.dispose();
    _ocr.dispose();
    super.dispose();
  }

  // ============================================================
  // CAPTURE DOCUMENT
  // ============================================================

  Future<void> _captureImage() async {
    if (!_cameraReady ||
        _isCapturing ||
        _isProcessing ||
        _capturedPhoto != null) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    bool captureSucceeded = false;

    try {
      // Stop live OCR before takePicture().
      await _camera.stopImageStream();

      // Full image capture — no square crop.
      final XFile? photo = await _camera.captureDocument();

      if (!mounted) return;

      if (photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capture failed — try again.')),
        );
        return;
      }

      captureSucceeded = true;

      setState(() {
        _capturedPhoto = photo;
        _detectedMedicines = [];
        _medicineInFrame = false;
      });

      await _processPhoto(photo);
    } catch (e, stackTrace) {
      debugPrint('Scan capture error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture image. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });

        // Capture failed/cancelled: restore live detection.
        if (!captureSucceeded && _capturedPhoto == null && _cameraReady) {
          await _startLiveDetection();
        }
      }
    }
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isProcessing) return;

    try {
      // Stop camera OCR while gallery is open.
      await _camera.stopImageStream();

      final XFile? photo = await _camera.pickFromGallery();

      if (!mounted) return;

      // User closed/cancelled gallery.
      if (photo == null) {
        if (_cameraReady && _capturedPhoto == null) {
          await _startLiveDetection();
        }

        return;
      }

      setState(() {
        _capturedPhoto = photo;
        _detectedMedicines = [];
        _medicineInFrame = false;
      });

      await _processPhoto(photo);
    } catch (e) {
      debugPrint('Gallery error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open image. Try again.')),
      );

      if (_cameraReady && _capturedPhoto == null) {
        await _startLiveDetection();
      }
    }
  }

  // ============================================================
  // OCR
  // ============================================================

  Future<void> _processPhoto(XFile photo) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _detectedMedicines = [];
    });

    try {
      final String text = await _ocr.readText(File(photo.path));

      debugPrint('');
      debugPrint('========== OCR TEXT ==========');
      debugPrint(text);
      debugPrint('==============================');
      debugPrint('');

      final List<DetectedMedicine> medicines = text.trim().isNotEmpty
          ? _ocr.detectMedicines(text)
          : <DetectedMedicine>[];

      if (!mounted) return;

      setState(() {
        _detectedMedicines = medicines;
      });

      if (medicines.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Text(
                medicines.length == 1
                    ? '✓ Detected: ${medicines.first.displayName}'
                    : '✓ ${medicines.length} medicines detected',
              ),
            ),
          );
      } else if (text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                'Text was detected, but medicine details '
                'could not be identified.',
              ),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 4),
              content: Text(
                'No text detected. Keep the document '
                'clear, flat and well lit.',
              ),
            ),
          );
      }
    } catch (e, stackTrace) {
      debugPrint('OCR processing error: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not read the image. Try again.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ============================================================
  // RETAKE
  // ============================================================

  Future<void> _retryCapture() async {
    if (_isProcessing || _isCapturing) return;

    setState(() {
      _capturedPhoto = null;
      _detectedMedicines = [];
      _medicineInFrame = false;
      _lastLiveScan = null;
    });

    if (_cameraReady) {
      await _startLiveDetection();
    }
  }

  // ============================================================
  // FLASH
  // ============================================================

  Future<void> _toggleFlash() async {
    if (!_cameraReady ||
        _capturedPhoto != null ||
        _isProcessing ||
        _isCapturing) {
      return;
    }

    await _camera.toggleFlash();

    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // MANUAL ENTRY
  // ============================================================

  void _enterManually() {
    // Manual form — scan fallback!
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddManualScreen()));
  }
  // ============================================================
  // REVIEW
  // ============================================================

  void _confirmMedicine(DetectedMedicine medicine) {
    final XFile? photo = _capturedPhoto;

    if (photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan the medicine again.')),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ReviewScanScreen(medicine: medicine, imagePath: photo.path),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildBody(),
              ),
            ),
          ),

          // Fixed camera controls instead of app bottom nav.
          _buildCameraControls(),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
          _buildCameraPreview(),

          const SizedBox(height: 12),

          // Only one instruction on the screen.
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.center_focus_strong_rounded,
                size: 16,
                color: AppColors.formAccent,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Fit the medicine label or full prescription inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          TextButton.icon(
            onPressed: _enterManually,
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Enter medication manually'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.formAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ====================================================
          // RETAKE
          // ====================================================
          if (_capturedPhoto != null) ...[
            const SizedBox(height: 4),

            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _retryCapture,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retake Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.formAccent,
                side: const BorderSide(color: AppColors.outline),
              ),
            ),
          ],

          // ====================================================
          // DETECTED MEDICINES
          // ====================================================
          if (_detectedMedicines.isNotEmpty) ...[
            const SizedBox(height: 12),

            ..._detectedMedicines.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDetectedCard(
                  medicine: entry.value,
                  index: entry.key,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PORTRAIT CAMERA / DOCUMENT PREVIEW
  // ============================================================

  Widget _buildCameraPreview() {
    return AspectRatio(
      // Portrait frame suitable for prescription pages.
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==================================================
            // LIVE CAMERA
            // ==================================================

            if (_capturedPhoto == null)
              if (_cameraReady) _camera.preview() else _buildCameraLoading(),

            // ==================================================
            // CAPTURED / GALLERY IMAGE
            // ==================================================
            if (_capturedPhoto != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Image.file(
                    File(_capturedPhoto!.path),

                    // Do not crop prescriptions.
                    fit: BoxFit.contain,

                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

            // ==================================================
            // SMART GREEN CORNERS
            // ==================================================
            if (_capturedPhoto == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(27, 30, 27, 48),
                    child: _ScannerFrame(active: _medicineInFrame),
                  ),
                ),
              ),

            // ==================================================
            // PROCESSING OVERLAY
            // ==================================================
            if (_isProcessing)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.30),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.headerDark.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Reading prescription...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ==================================================
            // CAMERA STATUS BAR
            // ==================================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.headerDark.withValues(alpha: 0.94),
                child: Row(
                  children: [
                    const Icon(
                      Icons.document_scanner_outlined,
                      size: 15,
                      color: Colors.white,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        _cameraStatusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.headerSubtext,
                          fontSize: 10,
                        ),
                      ),
                    ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _statusChipColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _ReadyDot(),

                          const SizedBox(width: 5),

                          Text(
                            _statusChipText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Color get _statusChipColor {
    if (_detectedMedicines.isNotEmpty) {
      return AppColors.success;
    }

    if (_medicineInFrame && _capturedPhoto == null) {
      return AppColors.scannerGreen;
    }

    return AppColors.headerDark;
  }

  String get _statusChipText {
    if (_isProcessing) {
      return 'READING';
    }

    if (_detectedMedicines.isNotEmpty) {
      return 'FOUND';
    }

    if (_medicineInFrame && _capturedPhoto == null) {
      return 'IN FRAME';
    }

    return 'READY';
  }

  // ============================================================
  // CAMERA STATUS TEXT
  // ============================================================

  String get _cameraStatusText {
    if (_cameraFailed) {
      return 'Camera unavailable';
    }

    if (!_cameraReady) {
      return 'Starting camera...';
    }

    if (_isCapturing) {
      return 'Capturing document...';
    }

    if (_isProcessing) {
      return 'Reading medicine text...';
    }

    if (_detectedMedicines.isNotEmpty) {
      if (_detectedMedicines.length == 1) {
        return 'Medicine detected';
      }

      return '${_detectedMedicines.length} medicines detected';
    }

    if (_capturedPhoto != null) {
      return 'Image captured';
    }

    if (_medicineInFrame) {
      return 'Medicine or prescription detected';
    }

    return 'Point camera at medicine or prescription';
  }

  // ============================================================
  // FIXED CAMERA CONTROLS
  // ============================================================

  Widget _buildCameraControls() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 10, 30, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =================================================
              // FLASH
              // =================================================

              _CameraAction(
                icon: _camera.flashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                label: 'Flash',
                active: _camera.flashOn,
                onTap: _toggleFlash,
              ),

              // =================================================
              // SHUTTER
              // =================================================
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap:
                        _capturedPhoto == null &&
                            !_isProcessing &&
                            !_isCapturing
                        ? _captureImage
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.formAccent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.formAccent.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _capturedPhoto != null
                              ? AppColors.fieldHint
                              : AppColors.formAccent,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing || _isProcessing
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.photo_camera_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Scan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              // =================================================
              // GALLERY
              // =================================================
              _CameraAction(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: _pickFromGallery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CAMERA LOADING
  // ============================================================

  Widget _buildCameraLoading() {
    return Container(
      color: AppColors.textPrimary.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: _cameraFailed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white,
                  size: 42,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Camera unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                FilledButton(
                  onPressed: () {
                    setState(() {
                      _cameraFailed = false;
                    });

                    _initCamera();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.formAccent,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            )
          : const CircularProgressIndicator(color: Colors.white),
    );
  }

  // ============================================================
  // DETECTED MEDICINE CARD
  // ============================================================

  Widget _buildDetectedCard({
    required DetectedMedicine medicine,
    required int index,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _detectedMedicines.length > 1
                      ? 'MEDICINE ${index + 1} DETECTED'
                      : 'MEDICINE DETECTED',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            medicine.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          if (medicine.strength != null &&
              medicine.strength!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),

            _medicineDetailRow(
              Icons.science_outlined,
              'Strength',
              medicine.strength!,
            ),
          ],

          if (medicine.form != null && medicine.form!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),

            _medicineDetailRow(
              Icons.medication_outlined,
              'Form',
              medicine.form!,
            ),
          ],

          if (medicine.frequency != null &&
              medicine.frequency!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),

            _medicineDetailRow(
              Icons.schedule_rounded,
              'Frequency',
              medicine.frequency!,
            ),
          ],

          if (medicine.instructions != null &&
              medicine.instructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 5),

            _medicineDetailRow(
              Icons.notes_rounded,
              'Instructions',
              medicine.instructions!,
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => _confirmMedicine(medicine),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.formAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Review & Add Medication',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.formAccent),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            '$title: $value',
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.formSubtitle,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                const Expanded(
                  child: Text(
                    'Add Medication',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.formIcon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
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

// ============================================================
// CAMERA ACTION
// ============================================================

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.formAccent.withValues(alpha: 0.12)
                    : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? AppColors.formAccent : AppColors.outline,
                ),
              ),
              child: Icon(icon, color: AppColors.formAccent, size: 23),
            ),

            const SizedBox(height: 5),

            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.formAccent : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMART SCANNER FRAME
// ============================================================

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),

      // Bright when medicine/prescription text is found.
      // Dim when camera is pointing at unrelated objects.
      opacity: active ? 1.0 : 0.25,

      child: CustomPaint(
        painter: _ScannerFramePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.scannerFrame
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double length = 25;

    // TOP LEFT
    canvas.drawLine(const Offset(0, length), const Offset(0, 0), paint);

    canvas.drawLine(const Offset(0, 0), const Offset(length, 0), paint);

    // TOP RIGHT
    canvas.drawLine(
      Offset(size.width - length, 0),
      Offset(size.width, 0),
      paint,
    );

    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // BOTTOM LEFT
    canvas.drawLine(
      Offset(0, size.height - length),
      Offset(0, size.height),
      paint,
    );

    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);

    // BOTTOM RIGHT
    canvas.drawLine(
      Offset(size.width - length, size.height),
      Offset(size.width, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// STATUS DOT
// ============================================================

class _ReadyDot extends StatelessWidget {
  const _ReadyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.streakFlame,
        shape: BoxShape.circle,
      ),
    );
  }
}
