import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;

  List<CameraDescription> _cameras = [];

  bool _initialized = false;
  bool _flashOn = false;
  bool _isCapturing = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isReady =>
      _initialized && _controller != null && _controller!.value.isInitialized;

  bool get flashOn => _flashOn;

  bool get isCapturing => _isCapturing;

  double get aspectRatio {
    if (!isReady) return 1;

    return _controller!.value.aspectRatio;
  }

  CameraController? get controller => _controller;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<bool> initialize() async {
    try {
      await _controller?.dispose();

      _controller = null;
      _initialized = false;
      _flashOn = false;
      _isCapturing = false;

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('CAMERA: No camera found.');
        return false;
      }

      final CameraDescription camera = _cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,

        // Prescription OCR ke liye high quality.
        ResolutionPreset.high,

        enableAudio: false,

        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      try {
        await _controller!.setFlashMode(FlashMode.off);
      } catch (_) {
        // Some devices may not expose flash.
      }

      // OCR/document scanning ke liye autofocus useful hai.
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      // Exposure ko auto rehne dein.
      try {
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      _initialized = true;

      debugPrint(
        'CAMERA READY: '
        '${camera.name}',
      );

      return true;
    } on CameraException catch (e) {
      debugPrint(
        'CameraException: '
        '${e.code} ${e.description}',
      );

      _initialized = false;

      return false;
    } catch (e, stackTrace) {
      debugPrint('Camera initialization error: $e');
      debugPrint('$stackTrace');

      _initialized = false;

      return false;
    }
  }

  // ============================================================
  // PREVIEW
  //
  // Works in:
  // - square viewport
  // - 3:4 document viewport
  // - other custom viewport sizes
  //
  // BoxFit.cover preserves camera proportions.
  // No stretching.
  // ============================================================

  Widget preview() {
    if (!isReady) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final CameraController controller = _controller!;

    final Size? previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return const ColoredBox(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewWidth = constraints.maxWidth;

        final double viewHeight = constraints.maxHeight;

        if (viewWidth <= 0 ||
            viewHeight <= 0 ||
            !viewWidth.isFinite ||
            !viewHeight.isFinite) {
          return const SizedBox.shrink();
        }

        // Camera previewSize is usually reported
        // in sensor/landscape orientation.
        // UI is portrait, so swap.
        final double cameraWidth = previewSize.height;

        final double cameraHeight = previewSize.width;

        return ClipRect(
          child: SizedBox(
            width: viewWidth,
            height: viewHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: cameraWidth,
                height: cameraHeight,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NORMAL RAW/FULL CAPTURE
  //
  // Kept for compatibility.
  // ============================================================

  Future<XFile?> capture() async {
    if (!isReady) {
      return null;
    }

    if (_isCapturing || _controller!.value.isTakingPicture) {
      return null;
    }

    try {
      _isCapturing = true;

      final XFile photo = await _controller!.takePicture();

      return photo;
    } on CameraException catch (e) {
      debugPrint(
        'Capture CameraException: '
        '${e.code} ${e.description}',
      );

      return null;
    } catch (e) {
      debugPrint('Capture error: $e');

      return null;
    } finally {
      _isCapturing = false;
    }
  }

  // ============================================================
  // DOCUMENT CAPTURE
  //
  // Recommended for:
  // - Full prescriptions
  // - Medicine boxes
  // - Medicine bottles
  // - Printed documents
  //
  // DIFFERENCE FROM captureSquare():
  //
  // captureSquare:
  // full sensor -> center square crop
  //
  // captureDocument:
  // full sensor -> orientation fix -> optional resize
  //
  // NO square crop.
  // NO top/bottom prescription loss.
  // ============================================================

  Future<XFile?> captureDocument() async {
    if (!isReady) {
      debugPrint('DOCUMENT CAPTURE: Camera not ready.');

      return null;
    }

    if (_isCapturing || _controller!.value.isTakingPicture) {
      debugPrint('DOCUMENT CAPTURE: Capture already running.');

      return null;
    }

    try {
      _isCapturing = true;

      // --------------------------------------------------------
      // Give autofocus a chance before taking document photo.
      // --------------------------------------------------------

      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      await Future<void>.delayed(const Duration(milliseconds: 120));

      // --------------------------------------------------------
      // Full-resolution image from camera
      // --------------------------------------------------------

      final XFile photo = await _controller!.takePicture();

      final File sourceFile = File(photo.path);

      if (!await sourceFile.exists()) {
        debugPrint('DOCUMENT CAPTURE: Source file missing.');

        return null;
      }

      final Uint8List bytes = await sourceFile.readAsBytes();

      img.Image? decoded = img.decodeImage(bytes);

      // If image package cannot decode it,
      // use original camera output rather than failing.
      if (decoded == null) {
        debugPrint(
          'DOCUMENT CAPTURE: '
          'Decode failed, using original image.',
        );

        return photo;
      }

      // --------------------------------------------------------
      // Correct EXIF orientation
      // --------------------------------------------------------

      decoded = img.bakeOrientation(decoded);

      debugPrint(
        'DOCUMENT ORIGINAL: '
        '${decoded.width}x${decoded.height}',
      );

      // --------------------------------------------------------
      // Preserve full document.
      //
      // We only reduce extremely large images.
      // Long side ~2400px gives OCR much more detail
      // than the old square 1400px output.
      // --------------------------------------------------------

      const int maxLongSide = 2400;

      img.Image outputImage = decoded;

      final int longSide = decoded.width > decoded.height
          ? decoded.width
          : decoded.height;

      if (longSide > maxLongSide) {
        if (decoded.width > decoded.height) {
          outputImage = img.copyResize(
            decoded,
            width: maxLongSide,
            interpolation: img.Interpolation.linear,
          );
        } else {
          outputImage = img.copyResize(
            decoded,
            height: maxLongSide,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      debugPrint(
        'DOCUMENT OUTPUT: '
        '${outputImage.width}x${outputImage.height}',
      );

      // --------------------------------------------------------
      // Save OCR-ready image
      // --------------------------------------------------------

      final Directory directory = await getTemporaryDirectory();

      final String outputPath =
          '${directory.path}/'
          'med_document_'
          '${DateTime.now().millisecondsSinceEpoch}'
          '.jpg';

      final File outputFile = File(outputPath);

      await outputFile.writeAsBytes(
        img.encodeJpg(outputImage, quality: 95),
        flush: true,
      );

      debugPrint(
        'DOCUMENT SAVED: '
        '${outputFile.path}',
      );

      return XFile(outputFile.path);
    } on CameraException catch (e) {
      debugPrint(
        'Document CameraException: '
        '${e.code} ${e.description}',
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint('Document capture error: $e');

      debugPrint('$stackTrace');

      return null;
    } finally {
      _isCapturing = false;
    }
  }

  // ============================================================
  // SQUARE CAPTURE
  //
  // Kept for backward compatibility.
  // New ScanLabelScreen should use captureDocument().
  // ============================================================

  Future<XFile?> captureSquare() async {
    if (!isReady) {
      return null;
    }

    if (_isCapturing || _controller!.value.isTakingPicture) {
      return null;
    }

    try {
      _isCapturing = true;

      final XFile photo = await _controller!.takePicture();

      final File sourceFile = File(photo.path);

      final Uint8List bytes = await sourceFile.readAsBytes();

      img.Image? decoded = img.decodeImage(bytes);

      if (decoded == null) {
        debugPrint('Could not decode captured image.');

        return photo;
      }

      decoded = img.bakeOrientation(decoded);

      final int squareSize = decoded.width < decoded.height
          ? decoded.width
          : decoded.height;

      final int cropX = (decoded.width - squareSize) ~/ 2;

      final int cropY = (decoded.height - squareSize) ~/ 2;

      final img.Image cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: squareSize,
        height: squareSize,
      );

      img.Image outputImage = cropped;

      if (cropped.width > 1400) {
        outputImage = img.copyResize(
          cropped,
          width: 1400,
          height: 1400,
          interpolation: img.Interpolation.linear,
        );
      }

      final Directory directory = await getTemporaryDirectory();

      final String outputPath =
          '${directory.path}/'
          'med_square_'
          '${DateTime.now().millisecondsSinceEpoch}'
          '.jpg';

      final File outputFile = File(outputPath);

      await outputFile.writeAsBytes(
        img.encodeJpg(outputImage, quality: 95),
        flush: true,
      );

      return XFile(outputFile.path);
    } catch (e, stackTrace) {
      debugPrint('Square capture error: $e');

      debugPrint('$stackTrace');

      return null;
    } finally {
      _isCapturing = false;
    }
  }
  // ============================================================
  // LIVE IMAGE STREAM
  // ============================================================

  Future<void> startImageStream(
    void Function(CameraImage image) onImage,
  ) async {
    if (!isReady) return;

    final controller = _controller!;

    if (controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream((CameraImage image) {
        onImage(image);
      });
    } catch (e) {
      debugPrint('Start image stream error: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (!isReady) return;

    final controller = _controller!;

    if (!controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('Stop image stream error: $e');
    }
  }

  int get sensorOrientation {
    return _controller?.description.sensorOrientation ?? 0;
  }

  CameraLensDirection get lensDirection {
    return _controller?.description.lensDirection ?? CameraLensDirection.back;
  }
  // ============================================================
  // FLASH
  // ============================================================

  Future<bool> toggleFlash() async {
    if (!isReady) {
      return _flashOn;
    }

    try {
      final bool newValue = !_flashOn;

      await _controller!.setFlashMode(
        newValue ? FlashMode.torch : FlashMode.off,
      );

      _flashOn = newValue;
    } catch (e) {
      debugPrint('Flash error: $e');

      _flashOn = false;
    }

    return _flashOn;
  }

  // ============================================================
  // FORCE FLASH OFF
  // ============================================================

  Future<void> flashOff() async {
    _flashOn = false;

    if (!isReady) {
      return;
    }

    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      debugPrint('Flash off error: $e');
    }
  }

  // ============================================================
  // GALLERY
  //
  // IMPORTANT:
  // Do not force square crop.
  // Full prescription/gallery image remains available to OCR.
  // ============================================================

  Future<XFile?> pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,

        // High OCR quality
        imageQuality: 95,

        // No cropWidth/cropHeight:
        // preserve full document.
      );

      return photo;
    } catch (e) {
      debugPrint('Gallery picker error: $e');

      return null;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    try {
      if (_controller != null) {
        try {
          await _controller!.setFlashMode(FlashMode.off);
        } catch (_) {}

        await _controller!.dispose();
      }
    } catch (e) {
      debugPrint('Camera dispose error: $e');
    }

    _controller = null;
    _initialized = false;
    _flashOn = false;
    _isCapturing = false;
  }
}
