import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../models/drug.dart';
import '../../repositories/drug_repository.dart';

/// Add Medication - Scan Screen (M4)
///
/// Lets the user take a photo of a prescription label OR pick from gallery.
/// OCR (google_mlkit_text_recognition) extracts text on-device (no server call).
/// Client-side regex parses strength, dose form, quantity, directions.
/// Drug name is matched against DrugRepository (drugs.json).
///
/// User always confirms the parsed fields before submitting (PRD 3).
class AddMedicationScanScreen extends StatefulWidget {
  final void Function(MedicationScanResult)? onScanComplete;

  const AddMedicationScanScreen({super.key, this.onScanComplete});

  @override
  State<AddMedicationScanScreen> createState() =>
      _AddMedicationScanScreenState();
}

class _AddMedicationScanScreenState extends State<AddMedicationScanScreen> {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  File? _imageFile;
  String _extractedText = '';
  bool _isProcessing = false;
  bool _hasScanned = false;

  final _drugNameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _doseFormController = TextEditingController();
  final _quantityController = TextEditingController();
  final _directionsController = TextEditingController();

  Drug? _matchedDrug;
  String? _errorMessage;

  @override
  void dispose() {
    _textRecognizer.close();
    _drugNameController.dispose();
    _strengthController.dispose();
    _doseFormController.dispose();
    _quantityController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  // ============================================================
  // IMAGE PICKING + OCR
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _imageFile = File(image.path);
        _isProcessing = true;
        _hasScanned = false;
        _errorMessage = null;
      });

      await _processImage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Failed to pick image: $e';
        });
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        setState(() {
          _extractedText = recognizedText.text;
          _isProcessing = false;
          _hasScanned = true;
        });
      }

      await _parseExtractedText(recognizedText.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'OCR failed: $e';
        });
      }
    }
  }

  // ============================================================
  // CLIENT-SIDE REGEX PARSING (Spark-compatible, no Cloud Function)
  // ============================================================

  Future<void> _parseExtractedText(String text) async {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // 1. Try to match drug name against DrugRepository
    String? drugName;
    Drug? matchedDrug;

    for (final line in lines) {
      final words = line.split(RegExp(r'\s+'));
      // Try first 1-3 words of each line
      for (
        int wordCount = 1;
        wordCount <= 3 && wordCount <= words.length;
        wordCount++
      ) {
        final candidate = words.take(wordCount).join(' ').trim();
        if (candidate.length < 3) continue;

        final results = await DrugRepository.instance.searchDrugs(
          candidate,
          limit: 1,
        );
        if (results.isNotEmpty) {
          drugName = results.first.name;
          matchedDrug = results.first;
          break;
        }
      }
      if (drugName != null) break;
    }

    // 2. Extract strength (e.g., "500 MG", "5 MCG", "10 ML")
    final strengthRegex = RegExp(
      r'\b(\d+\s*(?:MG|MCG|ML|G|IU|MG/ML|UNITS?))\b',
      caseSensitive: false,
    );
    final strengthMatch = strengthRegex.firstMatch(text);
    final strength = strengthMatch?.group(1);

    // 3. Extract dose form (e.g., "Tablet", "Capsule")
    final doseFormRegex = RegExp(
      r'\b(TABLETS?|CAPSULES?|SYRUP|INJECTION|SOLUTION|SUSPENSION|DROPS?)\b',
      caseSensitive: false,
    );
    final doseFormMatch = doseFormRegex.firstMatch(text);
    final doseForm = doseFormMatch?.group(1);

    // 4. Extract quantity (e.g., "30 tablets", "60 capsules")
    final quantityRegex = RegExp(
      r'\b(\d+)\s*(?:TABLETS?|CAPSULES?|ML|CAPS|TABS?)\b',
      caseSensitive: false,
    );
    final quantityMatch = quantityRegex.firstMatch(text);
    final quantity = quantityMatch?.group(1);

    // 5. Extract directions (lines with keywords like "Take", "twice", etc.)
    final directionsRegex = RegExp(
      r'.*?(?:take|once|twice|three times|daily|before|after|with food|empty stomach|morning|evening|night|hours?).*',
      caseSensitive: false,
    );
    final directionsMatches = directionsRegex.allMatches(text);
    final directions = directionsMatches
        .map((m) => m.group(0)?.trim())
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    if (mounted) {
      setState(() {
        _drugNameController.text = drugName ?? '';
        _strengthController.text = strength ?? '';
        _doseFormController.text = doseForm ?? '';
        _quantityController.text = quantity ?? '';
        _directionsController.text = directions;
        _matchedDrug = matchedDrug;
      });
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _onSubmit() {
    final result = MedicationScanResult(
      drugName: _drugNameController.text.trim(),
      strength: _strengthController.text.trim(),
      doseForm: _doseFormController.text.trim(),
      quantity: _quantityController.text.trim(),
      directions: _directionsController.text.trim(),
      matchedDrug: _matchedDrug,
      rawText: _extractedText,
    );

    if (widget.onScanComplete != null) {
      widget.onScanComplete!(result);
    }
    Navigator.of(context).pop(result);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isProcessing
                  ? _buildProcessingState()
                  : _hasScanned
                  ? _buildResultsView()
                  : _buildInitialState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Scan Medication Label',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner_rounded,
              size: 100,
              color: AppColors.fieldHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan Prescription Label',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo of the medication label to automatically extract drug name, strength, and directions.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Camera button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.formAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Gallery button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.formAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: AppColors.formAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_imageFile != null)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Processing image...',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Extracting text from label',
            style: TextStyle(fontSize: 13, color: AppColors.fieldHint),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imageFile != null)
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),

          if (_matchedDrug != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.formAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.formAccent, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.formAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Matched: ${_matchedDrug!.name}',
                      style: const TextStyle(
                        color: AppColors.formAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_drugNameController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drug "${_drugNameController.text}" not in catalog. You can still proceed.',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          _buildField(
            'Drug Name',
            _drugNameController,
            hint: 'e.g., Metformin',
          ),
          _buildField('Strength', _strengthController, hint: 'e.g., 500 MG'),
          _buildField('Dose Form', _doseFormController, hint: 'e.g., Tablet'),
          _buildField('Quantity', _quantityController, hint: 'e.g., 30'),
          _buildField(
            'Directions',
            _directionsController,
            hint: 'e.g., Take 1 tablet twice daily',
            maxLines: 3,
          ),

          const SizedBox(height: 8),

          ExpansionTile(
            title: const Text(
              'Show extracted text',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _extractedText.isEmpty
                      ? '(no text extracted)'
                      : _extractedText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: const Text('Re-scan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _drugNameController.text.trim().isEmpty
                      ? null
                      : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.formAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.fieldHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.formAccent,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Result returned from scan screen - pre-filled medication data
class MedicationScanResult {
  final String drugName;
  final String strength;
  final String doseForm;
  final String quantity;
  final String directions;
  final Drug? matchedDrug;
  final String rawText;

  const MedicationScanResult({
    required this.drugName,
    required this.strength,
    required this.doseForm,
    required this.quantity,
    required this.directions,
    this.matchedDrug,
    required this.rawText,
  });
}
