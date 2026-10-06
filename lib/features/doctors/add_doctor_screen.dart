import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../main_shell.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'doctors_data.dart';
import '../../core/profile/profile_controller.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  // ============================================================
  // MEDICATIONS
  // ============================================================

  static const List<({String name, String dose, String form, String freq})>
  _availableMeds = [
    (name: 'Metformin', dose: '500mg', form: 'Tablet', freq: '1x daily'),
    (name: 'Amlodipine', dose: '5mg', form: 'Tablet', freq: '1x daily'),
    (name: 'Vitamin D3 Drops', dose: '', form: 'Liquid', freq: '1x daily'),
  ];

  late final Map<String, bool> _linkedMeds;
  late final List<String> _linkedMedsOrder;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _clinicController;

  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _linkedMeds = {
      for (final med in _availableMeds)
        _medKey(med.name, med.dose): med.name != 'Vitamin D3 Drops',
    };

    _linkedMedsOrder = _availableMeds
        .map((med) => _medKey(med.name, med.dose))
        .toList();

    _nameController = TextEditingController(text: 'Dr. Ahmed Khan');

    _specialtyController = TextEditingController(text: 'General Physician');

    _phoneController = TextEditingController(text: '+1 (555) 987-6543');

    _clinicController = TextEditingController(
      text: 'City Care Clinic, Suite 4, Maple Street',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _clinicController.dispose();

    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _medKey(String name, String dose) {
    return dose.isEmpty ? name : '$name $dose';
  }

  List<String> get _selectedMeds {
    return _linkedMedsOrder.where((key) => _linkedMeds[key] == true).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  void _onBottomNavigationTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: index)),
      (route) => false,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _saveDoctor() {
    if (_isSaving) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter the doctor\'s full name.');
      return;
    }

    final specialty = _specialtyController.text.trim();
    final phone = _phoneController.text.trim();
    final clinic = _clinicController.text.trim();

    setState(() {
      _isSaving = true;
    });

    DoctorsData.addDoctor(
      memberId: ProfileController.instance.memberId ?? '',
      name: name,
      specialty: specialty,
      phone: phone,
      clinicAddress: clinic.isEmpty ? null : clinic,
      linkedMeds: _selectedMeds,
    );

    Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
      if (!mounted) return;

      Navigator.of(context).pop(true);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerDark,
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
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 0,
        onTap: _onBottomNavigationTap,
      ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
              ),

              const SizedBox(width: 2),

              const Expanded(
                child: Text(
                  'Add Doctor',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const AppAvatar(
                size: 35,
                ringColor: AppColors.surface,
                ringWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'DOCTOR DETAILS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 14),

        _buildFieldLabel('Full Name *'),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _nameController,
          hintText: 'Enter full name',
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 14),

        _buildFieldLabel('Specialty'),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _specialtyController,
          hintText: 'Enter specialty',
          textInputAction: TextInputAction.next,
        ),

        const SizedBox(height: 14),

        _buildFieldLabel('Phone Number'),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _phoneController,
          hintText: 'Enter phone number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          suffixIcon: const Icon(
            Icons.phone_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
          ],
        ),

        const SizedBox(height: 14),

        _buildFieldLabel('Clinic / Address (optional)'),

        const SizedBox(height: 6),

        _buildTextField(
          controller: _clinicController,
          hintText: 'Enter clinic or address',
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.done,
          maxLines: 2,
          minHeight: 72,
        ),

        const SizedBox(height: 26),

        // ======================================================
        // LINK MEDICATIONS
        // ======================================================
        const Text(
          'LINK TO MEDICATIONS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Which medications does this doctor prescribe?',
          style: TextStyle(
            color: AppColors.textTeal,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 6),

        _buildMedicationsCard(),

        const SizedBox(height: 20),

        // ======================================================
        // SAVE
        // ======================================================
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.primaryDark.withValues(
                alpha: 0.65,
              ),
              elevation: 4,
              shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Text(
                    'Save Doctor',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // ======================================================
        // CANCEL
        // ======================================================
        Center(
          child: TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textTeal,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int maxLines = 1,
    double minHeight = 50,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.fieldHint,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.textTeal, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.textTeal),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATIONS CARD
  // ============================================================

  Widget _buildMedicationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < _availableMeds.length; i++) ...[
            _buildMedicationRow(_availableMeds[i]),
            if (i != _availableMeds.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.inputFill,
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MEDICATION ROW
  // ============================================================

  Widget _buildMedicationRow(
    ({String name, String dose, String form, String freq}) med,
  ) {
    final key = _medKey(med.name, med.dose);

    final selected = _linkedMeds[key] ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          // Medication icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inputFill),
            ),
            child: Icon(
              med.form == 'Liquid'
                  ? Icons.medication_liquid_outlined
                  : Icons.medication_outlined,
              color: AppColors.textTeal,
              size: 18,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${med.form} · ${med.freq}',
                  style: const TextStyle(
                    color: AppColors.textTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Transform.scale(
            scale: 0.82,
            child: Switch(
              value: selected,
              onChanged: (value) {
                setState(() {
                  _linkedMeds[key] = value;
                });
              },
              activeColor: AppColors.surface,
              activeTrackColor: AppColors.primaryDark,
              inactiveThumbColor: AppColors.surface,
              inactiveTrackColor: AppColors.divider,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
