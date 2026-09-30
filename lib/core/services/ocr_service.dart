import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// ============================================================
/// DETECTED MEDICINE
/// ============================================================

class DetectedMedicine {
  const DetectedMedicine({
    required this.name,
    this.strength,
    this.form,
    this.frequency,
    this.instructions,
    this.confidence = 0.5,
  });

  final String name;
  final String? strength;
  final String? form;
  final String? frequency;
  final String? instructions;
  final double confidence;

  String get displayName {
    final s = strength?.trim();

    if (s == null || s.isEmpty) {
      return name;
    }

    return '$name $s';
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      if (strength != null && strength!.isNotEmpty) 'strength': strength!,
      if (form != null && form!.isNotEmpty) 'form': form!,
      if (frequency != null && frequency!.isNotEmpty) 'frequency': frequency!,
      if (instructions != null && instructions!.isNotEmpty)
        'instructions': instructions!,
    };
  }
}

/// ============================================================
/// OCR SERVICE
/// ============================================================

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // ============================================================
  // CAPTURED IMAGE / GALLERY OCR
  // ============================================================

  Future<String> readText(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        debugPrint('OCR: image does not exist');
        return '';
      }

      final input = InputImage.fromFile(imageFile);

      final RecognizedText result = await _textRecognizer.processImage(input);

      final text = result.text.trim();

      debugPrint('');
      debugPrint('==============================');
      debugPrint('RAW OCR TEXT');
      debugPrint('==============================');
      debugPrint(text);
      debugPrint('==============================');
      debugPrint('');

      return text;
    } catch (e, stack) {
      debugPrint('OCR ERROR: $e');
      debugPrint('$stack');

      return '';
    }
  }

  // ============================================================
  // LIVE CAMERA OCR
  //
  // Used only for:
  // DIM frame -> GREEN frame
  //
  // This does NOT add medicine automatically.
  // Final OCR still runs after photo capture.
  // ============================================================

  Future<String> readCameraFrame({
    required CameraImage image,
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
    required DeviceOrientation deviceOrientation,
  }) async {
    try {
      final InputImageRotation? rotation = _rotationForCameraFrame(
        sensorOrientation: sensorOrientation,
        lensDirection: lensDirection,
        deviceOrientation: deviceOrientation,
      );

      if (rotation == null) {
        return '';
      }

      final InputImageFormat? format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );

      if (format == null) {
        return '';
      }

      // Our CameraService requests:
      //
      // Android -> NV21
      // iOS     -> BGRA8888
      //
      // Both should reach ML Kit as
      // a single plane.
      if (image.planes.length != 1) {
        debugPrint(
          'LIVE OCR: unsupported plane count '
          '${image.planes.length}',
        );

        return '';
      }

      final Plane plane = image.planes.first;

      final InputImage inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );

      final RecognizedText result = await _textRecognizer.processImage(
        inputImage,
      );

      return result.text.trim();
    } catch (e) {
      debugPrint('LIVE OCR ERROR: $e');

      return '';
    }
  }

  // ============================================================
  // CAMERA FRAME ROTATION
  // ============================================================

  InputImageRotation? _rotationForCameraFrame({
    required int sensorOrientation,
    required CameraLensDirection lensDirection,
    required DeviceOrientation deviceOrientation,
  }) {
    final Map<DeviceOrientation, int> orientationDegrees = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final int? deviceDegrees = orientationDegrees[deviceOrientation];

    if (deviceDegrees == null) {
      return null;
    }

    int rotationDegrees;

    if (Platform.isIOS) {
      // On iOS sensor orientation can normally
      // be used directly.
      rotationDegrees = sensorOrientation;
    } else {
      // Android camera rotation compensation.
      if (lensDirection == CameraLensDirection.front) {
        rotationDegrees = (sensorOrientation + deviceDegrees) % 360;
      } else {
        rotationDegrees = (sensorOrientation - deviceDegrees + 360) % 360;
      }
    }

    return InputImageRotationValue.fromRawValue(rotationDegrees);
  }

  // ============================================================
  // MULTIPLE MEDICINE DETECTION
  // ============================================================

  List<DetectedMedicine> detectMedicines(String ocrText) {
    if (ocrText.trim().isEmpty) {
      return [];
    }

    final lines = ocrText
        .split(RegExp(r'[\r\n]+'))
        .map(_cleanLine)
        .where((e) => e.isNotEmpty)
        .toList();

    debugPrint('');
    debugPrint('======= CLEANED OCR LINES =======');

    for (int i = 0; i < lines.length; i++) {
      debugPrint('[$i] ${lines[i]}');
    }

    debugPrint('=================================');

    final List<DetectedMedicine> medicines = [];

    // ==========================================================
    // PASS 1
    // Find strength and then medicine around it.
    // ==========================================================

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      final matches = _strengthRegex.allMatches(line).toList();

      if (matches.isEmpty) {
        continue;
      }

      for (final strengthMatch in matches) {
        final strength = _normalizeStrength(strengthMatch);

        final name = _findMedicineName(
          lines: lines,
          strengthIndex: i,
          strengthMatch: strengthMatch,
        );

        if (name == null) {
          debugPrint(
            'Strength found but name '
            'not found: $line',
          );

          continue;
        }

        final context = _medicineContext(lines, i);

        final form = _detectForm(context);

        final medicine = DetectedMedicine(
          name: name,
          strength: strength,
          form: form,
          frequency: _detectFrequency(context),
          instructions: _detectInstructions(context),
          confidence: _calculateConfidence(
            name: name,
            strength: strength,
            form: form,
          ),
        );

        _addIfUnique(medicines, medicine);
      }
    }

    // ==========================================================
    // PASS 2
    // Name/form fallback if strength wasn't readable.
    // ==========================================================

    if (medicines.isEmpty) {
      final fallback = _detectWithoutStrength(lines);

      if (fallback != null) {
        medicines.add(fallback);
      }
    }

    debugPrint('');
    debugPrint(
      '===== DETECTED '
      '${medicines.length} '
      'MEDICINE(S) =====',
    );

    for (final m in medicines) {
      debugPrint('NAME: ${m.name}');
      debugPrint('STRENGTH: ${m.strength}');
      debugPrint('FORM: ${m.form}');
      debugPrint('FREQUENCY: ${m.frequency}');
      debugPrint(
        'INSTRUCTIONS: '
        '${m.instructions}',
      );
      debugPrint('--------------------------');
    }

    return medicines;
  }

  // ============================================================
  // FIRST MEDICINE
  // ============================================================

  DetectedMedicine? detectMedicine(String ocrText) {
    final medicines = detectMedicines(ocrText);

    if (medicines.isEmpty) {
      return null;
    }

    return medicines.first;
  }

  // ============================================================
  // FIND MEDICINE NAME
  // ============================================================

  String? _findMedicineName({
    required List<String> lines,
    required int strengthIndex,
    required RegExpMatch strengthMatch,
  }) {
    final strengthLine = lines[strengthIndex];

    // ----------------------------------------------------------
    // SAME LINE - BEFORE STRENGTH
    //
    // Metformin 500 mg
    // ----------------------------------------------------------

    var before = strengthLine.substring(0, strengthMatch.start).trim();

    before = _removePackagingTerms(before);

    final sameLineBefore = _extractName(before);

    if (sameLineBefore != null) {
      return sameLineBefore;
    }

    // ----------------------------------------------------------
    // SAME LINE - AFTER STRENGTH
    //
    // 500 mg Metformin
    // ----------------------------------------------------------

    var after = strengthLine.substring(strengthMatch.end).trim();

    after = _removePackagingTerms(after);

    final sameLineAfter = _extractName(after);

    if (sameLineAfter != null) {
      return sameLineAfter;
    }

    // ----------------------------------------------------------
    // SEARCH PREVIOUS 3 LINES
    // ----------------------------------------------------------

    final int start = (strengthIndex - 3).clamp(0, lines.length);

    for (int i = strengthIndex - 1; i >= start; i--) {
      var candidate = lines[i];

      if (_isPackagingOnlyLine(candidate)) {
        continue;
      }

      candidate = _removePackagingTerms(candidate);

      final name = _extractName(candidate);

      if (name != null) {
        if (_isGenericSuffix(name) && i > 0) {
          final previous = _extractName(_removePackagingTerms(lines[i - 1]));

          if (previous != null) {
            return _titleCase('$previous $name');
          }
        }

        return name;
      }
    }

    // ----------------------------------------------------------
    // SEARCH NEXT 2 LINES
    // ----------------------------------------------------------

    final int end = (strengthIndex + 3).clamp(0, lines.length);

    for (int i = strengthIndex + 1; i < end; i++) {
      var candidate = lines[i];

      if (_isPackagingOnlyLine(candidate)) {
        continue;
      }

      candidate = _removePackagingTerms(candidate);

      final name = _extractName(candidate);

      if (name != null) {
        return name;
      }
    }

    return null;
  }

  // ============================================================
  // FALLBACK WITHOUT STRENGTH
  // ============================================================

  DetectedMedicine? _detectWithoutStrength(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (_isPackagingOnlyLine(line)) {
        continue;
      }

      final candidate = _extractName(_removePackagingTerms(line));

      if (candidate == null) {
        continue;
      }

      final context = _medicineContext(lines, i);

      final form = _detectForm(context);

      final hasMedicineWord = _hasMedicineEvidence(context);

      if (form != null || hasMedicineWord) {
        return DetectedMedicine(
          name: candidate,
          form: form,
          frequency: _detectFrequency(context),
          instructions: _detectInstructions(context),
          confidence: 0.45,
        );
      }
    }

    return null;
  }

  bool _hasMedicineEvidence(List<String> lines) {
    final text = lines.join(' ').toLowerCase();

    return RegExp(
      r'\b('
      r'tablet|tablets|tab|tabs|'
      r'capsule|capsules|cap|caps|'
      r'syrup|suspension|solution|'
      r'drops|cream|ointment|'
      r'injection|inhaler|patch|spray|'
      r'oral|dose|dosage|'
      r'take|prescription|rx'
      r')\b',
    ).hasMatch(text);
  }

  // ============================================================
  // STRENGTH
  // ============================================================

  static final RegExp _strengthRegex = RegExp(
    r'(?<![A-Za-z0-9])'
    r'(\d+(?:[.,]\d+)?)'
    r'\s*'
    r'(mg|mcg|µg|μg|ug|g|iu|i\.u\.|units?|ml|mL)'
    r'(?:'
    r'\s*/\s*'
    r'(\d+(?:[.,]\d+)?)?'
    r'\s*'
    r'(ml|mL|mg|mcg|g)'
    r')?',
    caseSensitive: false,
  );

  String _normalizeStrength(RegExpMatch match) {
    var value = match.group(1) ?? '';

    value = value.replaceAll(',', '.');

    var unit = (match.group(2) ?? '').toLowerCase();

    if (unit == 'µg' || unit == 'μg' || unit == 'ug') {
      unit = 'mcg';
    }

    if (unit == 'i.u.' || unit == 'iu') {
      unit = 'IU';
    } else if (unit == 'ml') {
      unit = 'mL';
    }

    final denominatorValue = match.group(3);

    var denominatorUnit = match.group(4);

    String output = '$value $unit';

    if (denominatorUnit != null) {
      denominatorUnit = denominatorUnit.toLowerCase();

      if (denominatorUnit == 'ml') {
        denominatorUnit = 'mL';
      }

      output += '/';

      if (denominatorValue != null && denominatorValue.isNotEmpty) {
        output += denominatorValue.replaceAll(',', '.');
      }

      output += denominatorUnit;
    }

    return output;
  }

  // ============================================================
  // NAME
  // ============================================================

  String? _extractName(String input) {
    var text = input.trim();

    if (text.isEmpty) {
      return null;
    }

    text = text.replaceAll(
      RegExp(
        r'^(rx|rx only|medicine|'
        r'medication|drug|generic|'
        r'brand|name)\s*[:\-]*\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceFirst(RegExp(r'^\s*\d+\s*[\.\)\-:]\s*'), '');

    // Remove forms from name.
    text = text.replaceAll(
      RegExp(
        r'\b('
        r'tablets?|tabs?|'
        r'capsules?|caps?|'
        r'syrup|solution|'
        r'suspension|drops?|'
        r'cream|ointment|'
        r'injection|inhaler|'
        r'patch|spray'
        r')\b',
        caseSensitive: false,
      ),
      ' ',
    );

    // Remove pharmacopoeia labels.
    text = text.replaceAll(
      RegExp(
        r'\b('
        r'BP|USP|IP|EP|'
        r'B\.P\.|U\.S\.P\.|'
        r'I\.P\.'
        r')\b',
        caseSensitive: false,
      ),
      ' ',
    );

    text = text
        .replaceAll(RegExp(r'[^A-Za-z0-9+\- ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (!_looksLikeMedicineName(text)) {
      return null;
    }

    var words = text.split(' ');

    words = words
        .where((word) => !_nameStopWords.contains(word.toLowerCase()))
        .toList();

    if (words.isEmpty) {
      return null;
    }

    if (words.length > 5) {
      words = words.take(5).toList();
    }

    final name = words.join(' ').trim();

    if (!_looksLikeMedicineName(name)) {
      return null;
    }

    return _titleCase(name);
  }

  bool _looksLikeMedicineName(String input) {
    final text = input.trim();

    if (text.length < 3 || text.length > 70) {
      return false;
    }

    if (!RegExp(r'[A-Za-z]{3,}').hasMatch(text)) {
      return false;
    }

    final lower = text.toLowerCase();

    if (_genericSuffixes.contains(lower)) {
      return false;
    }

    for (final phrase in _rejectPhrases) {
      if (lower.contains(phrase)) {
        return false;
      }
    }

    if (RegExp(
      r'^(take|use|apply|'
      r'swallow|shake|keep|'
      r'store|warning|dose|'
      r'dosage)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return false;
    }

    final letters = RegExp(r'[A-Za-z]').allMatches(text).length;

    final digits = RegExp(r'\d').allMatches(text).length;

    if (digits > letters * 2) {
      return false;
    }

    return true;
  }

  // ============================================================
  // PACKAGING CLEANING
  // ============================================================

  String _removePackagingTerms(String text) {
    var value = text;

    value = value.replaceAll(
      RegExp(
        r'\b('
        r'BP|USP|IP|EP|'
        r'B\.P\.|U\.S\.P\.|'
        r'I\.P\.|'
        r'each|contains?|'
        r'equivalent to|'
        r'film coated|'
        r'film-coated|'
        r'oral|'
        r'dosage|'
        r'composition'
        r')\b',
        caseSensitive: false,
      ),
      ' ',
    );

    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isPackagingOnlyLine(String input) {
    final lower = input.toLowerCase().trim();

    if (lower.isEmpty) {
      return true;
    }

    if (_strengthRegex.hasMatch(lower) &&
        lower
            .replaceAll(_strengthRegex, '')
            .replaceAll(RegExp(r'[^a-z]'), '')
            .isEmpty) {
      return true;
    }

    final patterns = [
      r'^tablets?$',
      r'^capsules?$',
      r'^film[- ]?coated tablets?$',
      r'^oral use$',
      r'^for oral use$',
      r'^prescription only$',
      r'^rx only$',
      r'^keep out of reach',
      r'^store ',
      r'^batch',
      r'^lot',
      r'^exp',
      r'^expiry',
      r'^mfg',
      r'^manufactured',
      r'^marketed',
      r'^distributed',
      r'^composition',
      r'^dosage',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lower)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // FORM
  // ============================================================

  String? _detectForm(List<String> lines) {
    final text = lines.join(' ').toLowerCase();

    final forms = <RegExp, String>{
      RegExp(r'\b(tablet|tablets|tab|tabs)\b'): 'Tablet',
      RegExp(r'\b(capsule|capsules|cap|caps)\b'): 'Capsule',
      RegExp(r'\bsyrup\b'): 'Syrup',
      RegExp(r'\bsuspension\b'): 'Suspension',
      RegExp(r'\bsolution\b'): 'Solution',
      RegExp(r'\b(drop|drops)\b'): 'Drops',
      RegExp(r'\bcream\b'): 'Cream',
      RegExp(r'\bointment\b'): 'Ointment',
      RegExp(r'\binjection\b'): 'Injection',
      RegExp(r'\binhaler\b'): 'Inhaler',
      RegExp(r'\bpatch\b'): 'Patch',
      RegExp(r'\bspray\b'): 'Spray',
    };

    for (final entry in forms.entries) {
      if (entry.key.hasMatch(text)) {
        return entry.value;
      }
    }

    return null;
  }

  // ============================================================
  // FREQUENCY
  // ============================================================

  String? _detectFrequency(List<String> lines) {
    final text = lines.join(' ').toLowerCase();

    if (RegExp(
      r'\b(once daily|once a day|'
      r'1 time daily|every day)\b',
    ).hasMatch(text)) {
      return 'Once daily';
    }

    if (RegExp(
      r'\b(twice daily|twice a day|'
      r'2 times daily)\b',
    ).hasMatch(text)) {
      return 'Twice daily';
    }

    if (RegExp(
      r'\b(three times daily|'
      r'3 times daily)\b',
    ).hasMatch(text)) {
      return '3 times daily';
    }

    if (RegExp(
      r'\b(four times daily|'
      r'4 times daily)\b',
    ).hasMatch(text)) {
      return '4 times daily';
    }

    if (RegExp(r'\b(bid|bd)\b').hasMatch(text)) {
      return 'Twice daily';
    }

    if (RegExp(r'\b(tid|tds)\b').hasMatch(text)) {
      return '3 times daily';
    }

    if (RegExp(r'\bqid\b').hasMatch(text)) {
      return '4 times daily';
    }

    // Must still be confirmed by user.
    if (RegExp(r'\b(od|qd)\b').hasMatch(text)) {
      return 'Once daily';
    }

    if (RegExp(
      r'\bqhs\b|'
      r'\bat bedtime\b|'
      r'\bbefore bed\b',
    ).hasMatch(text)) {
      return 'At bedtime';
    }

    final everyHours = RegExp(
      r'\bevery\s+(\d{1,2})'
      r'\s*hours?\b',
    ).firstMatch(text);

    if (everyHours != null) {
      return 'Every '
          '${everyHours.group(1)} '
          'hours';
    }

    return null;
  }

  // ============================================================
  // INSTRUCTIONS
  // ============================================================

  String? _detectInstructions(List<String> lines) {
    for (final line in lines) {
      if (RegExp(
        r'\b('
        r'take|use|apply|'
        r'swallow|with food|'
        r'after food|before food|'
        r'after breakfast|'
        r'before breakfast|'
        r'at bedtime'
        r')\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        return line;
      }
    }

    return null;
  }

  // ============================================================
  // CONTEXT
  // ============================================================

  List<String> _medicineContext(List<String> lines, int index) {
    final start = (index - 2).clamp(0, lines.length);

    final end = (index + 4).clamp(0, lines.length);

    return lines.sublist(start, end);
  }

  // ============================================================
  // CONFIDENCE
  // ============================================================

  double _calculateConfidence({
    required String name,
    String? strength,
    String? form,
  }) {
    double confidence = 0.55;

    if (name.isNotEmpty) {
      confidence += 0.15;
    }

    if (strength != null && strength.isNotEmpty) {
      confidence += 0.15;
    }

    if (form != null && form.isNotEmpty) {
      confidence += 0.10;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // ============================================================
  // DUPLICATE PREVENTION
  // ============================================================

  void _addIfUnique(
    List<DetectedMedicine> medicines,
    DetectedMedicine candidate,
  ) {
    final candidateName = candidate.name.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final candidateStrength = (candidate.strength ?? '').toLowerCase();

    final exists = medicines.any(
      (m) =>
          m.name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
              candidateName &&
          (m.strength ?? '').toLowerCase() == candidateStrength,
    );

    if (!exists) {
      medicines.add(candidate);
    }
  }

  // ============================================================
  // CLEAN
  // ============================================================

  String _cleanLine(String input) {
    return input
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('：', ':')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((word) {
          if (word.length <= 2 && word == word.toUpperCase()) {
            return word;
          }

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  bool _isGenericSuffix(String value) {
    return _genericSuffixes.contains(value.toLowerCase().trim());
  }

  // ============================================================
  // STOP / REJECT WORDS
  // ============================================================

  static const Set<String> _genericSuffixes = {
    'hydrochloride',
    'sodium',
    'potassium',
    'maleate',
    'besylate',
    'besilate',
    'succinate',
    'tartrate',
    'citrate',
    'phosphate',
  };

  static const Set<String> _nameStopWords = {
    'rx',
    'only',
    'drug',
    'medicine',
    'medication',
    'name',
    'generic',
    'brand',
    'take',
    'use',
    'oral',
    'for',
    'the',
    'each',
    'contains',
    'contain',
    'bp',
    'usp',
    'ip',
    'ep',
  };

  static const List<String> _rejectPhrases = [
    'pharmacy',
    'doctor',
    'physician',
    'patient',
    'address',
    'telephone',
    'phone',
    'refill',
    'prescription number',
    'rx number',
    'date of birth',
    'dob',
    'quantity',
    'warning',
    'keep out',
    'manufacturer',
    'manufactured by',
    'marketed by',
    'distributed by',
    'batch no',
    'batch number',
    'lot no',
    'expiry',
    'expires',
    'storage',
    'store below',
    'keep below',
    'children',
    'composition',
    'directions for use',
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
