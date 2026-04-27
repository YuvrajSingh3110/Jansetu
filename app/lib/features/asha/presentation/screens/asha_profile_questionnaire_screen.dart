import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_worker_profile_repository.dart';
import 'package:jansetu/features/asha/presentation/screens/asha_dashboard_screen.dart';

class AshaProfileQuestionnaireScreen extends StatefulWidget {
  const AshaProfileQuestionnaireScreen({super.key, this.initialProfile});

  final AshaWorkerProfile? initialProfile;

  @override
  State<AshaProfileQuestionnaireScreen> createState() =>
      _AshaProfileQuestionnaireScreenState();
}

class _AshaProfileQuestionnaireScreenState
    extends State<AshaProfileQuestionnaireScreen> {
  final PageController _controller = PageController();
  final AshaWorkerProfileRepository _repository = AshaWorkerProfileRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _employeeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _officeController;
  late final TextEditingController _supervisorController;
  late final TextEditingController _villageController;

  int _pageIndex = 0;
  String? _designation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProfile;
    _nameController = TextEditingController(text: initial?.fullName ?? '');
    _employeeController = TextEditingController(text: initial?.employeeId ?? '');
    _phoneController = TextEditingController(text: initial?.phoneNumber ?? '');
    _officeController = TextEditingController(text: initial?.reportingOffice ?? '');
    _supervisorController =
        TextEditingController(text: initial?.supervisorName ?? '');
    _villageController = TextEditingController(text: initial?.primaryVillage ?? '');
    _designation = initial?.designation;

    for (final controller in [
      _nameController,
      _employeeController,
      _phoneController,
      _officeController,
      _supervisorController,
      _villageController,
    ]) {
      controller.addListener(_handleFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _employeeController,
      _phoneController,
      _officeController,
      _supervisorController,
      _villageController,
    ]) {
      controller.removeListener(_handleFieldChanged);
    }
    _controller.dispose();
    _nameController.dispose();
    _employeeController.dispose();
    _phoneController.dispose();
    _officeController.dispose();
    _supervisorController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleImmediateInput(String _) {
    if (!mounted) return;
    setState(() {});
  }

  bool _isCurrentStepValid() {
    switch (_pageIndex) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _employeeController.text.trim().isNotEmpty;
      case 2:
        return _phoneController.text.trim().isNotEmpty;
      case 3:
        return _designation != null;
      case 4:
        return _officeController.text.trim().isNotEmpty;
      case 5:
        return _supervisorController.text.trim().isNotEmpty &&
            _villageController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _goNext() async {
    if (!_isCurrentStepValid()) return;
    if (_pageIndex == 5) {
      await _saveAndContinue();
      return;
    }
    final nextIndex = _pageIndex + 1;
    await _controller.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _pageIndex = nextIndex;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final profile = AshaWorkerProfile(
      fullName: _nameController.text.trim(),
      employeeId: _employeeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      designation: _designation ?? 'ASHA',
      reportingOffice: _officeController.text.trim(),
      supervisorName: _supervisorController.text.trim(),
      primaryVillage: _villageController.text.trim(),
      profileImagePath: widget.initialProfile?.profileImagePath,
    );
    await _repository.saveProfile(profile);
    if (!mounted) return;
    if (widget.initialProfile != null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AshaDashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _QuestionStep(
        title: 'What should we call you?',
        subtitle: 'Your name will appear on your dashboard and reports.',
        child: _StyledTextField(
          controller: _nameController,
          hintText: 'Seema Devi',
          onChanged: _handleImmediateInput,
        ),
      ),
      _QuestionStep(
        title: 'What is your CHW employee ID?',
        subtitle: 'We use this to pull your server profile and reporting history.',
        child: _StyledTextField(
          controller: _employeeController,
          hintText: 'VR-2841',
          textCapitalization: TextCapitalization.characters,
          onChanged: _handleImmediateInput,
        ),
      ),
      _QuestionStep(
        title: 'Which phone number should we save?',
        subtitle: 'This helps with follow-up and office coordination.',
        child: _StyledTextField(
          controller: _phoneController,
          hintText: '+91 90000 12345',
          keyboardType: TextInputType.phone,
          onChanged: _handleImmediateInput,
        ),
      ),
      _QuestionStep(
        title: 'What is your role?',
        subtitle: 'Pick the closest match for your field work.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['ASHA', 'ANM', 'CHW']
              .map(
                (option) => _ChoiceChipCard(
                  label: option,
                  isSelected: _designation == option,
                  onTap: () => setState(() => _designation = option),
                ),
              )
              .toList(),
        ),
      ),
      _QuestionStep(
        title: 'Which office do you report to?',
        subtitle: 'Block office, PHC, or sub-centre name.',
        child: _StyledTextField(
          controller: _officeController,
          hintText: 'Rampur Block PHC',
          onChanged: _handleImmediateInput,
        ),
      ),
      _QuestionStep(
        title: 'Who is your supervisor and primary village?',
        subtitle: 'We use this to personalize your profile and cluster map.',
        child: Column(
          children: [
            _StyledTextField(
              controller: _supervisorController,
              hintText: 'Supervisor name',
              onChanged: _handleImmediateInput,
            ),
            const SizedBox(height: 14),
            _StyledTextField(
              controller: _villageController,
              hintText: 'Primary village',
              onChanged: _handleImmediateInput,
            ),
          ],
        ),
      ),
    ];
    final canProceed = _isCurrentStepValid() && !_isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_pageIndex + 1) / steps.length,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFDDE7F2),
                      borderRadius: BorderRadius.circular(999),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF2368AF)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_pageIndex + 1}/${steps.length}',
                    style: const TextStyle(
                      color: Color(0xFF556275),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                onPageChanged: (index) {
                  if (_pageIndex == index || !mounted) return;
                  setState(() => _pageIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: steps[index],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final nextIndex = _pageIndex - 1;
                          await _controller.animateToPage(
                            nextIndex,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          );
                          if (!mounted) return;
                          setState(() => _pageIndex = nextIndex);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          side: const BorderSide(color: Color(0xFFD4DDE8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_pageIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canProceed ? _goNext : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 54),
                        backgroundColor: const Color(0xFF2368AF),
                        disabledBackgroundColor: const Color(0xFFB8C7D8),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(_isSaving
                          ? 'Saving...'
                          : _pageIndex == steps.length - 1
                              ? 'Finish setup'
                              : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18314F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Color(0xFF617087),
            ),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF6F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E1EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E1EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF2368AF), width: 1.4),
        ),
      ),
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F0FB) : const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF2368AF) : const Color(0xFFD9E1EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF2368AF) : const Color(0xFF425268),
          ),
        ),
      ),
    );
  }
}
