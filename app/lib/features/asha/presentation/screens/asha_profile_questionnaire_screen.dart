import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:jansetu/features/asha/data/asha_models.dart';
import 'package:jansetu/features/asha/data/asha_repository.dart';
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
  final AshaWorkerProfileRepository _profileRepository =
      AshaWorkerProfileRepository();
  final AshaRepository _repository = AshaRepository();

  late final TextEditingController _nameController;
  late final TextEditingController _employeeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _villageSearchController;

  int _pageIndex = 0;
  bool _isSaving = false;
  bool _isLoadingDistricts = true;
  bool _isLoadingProfile = false;
  String? _designation;
  String? _selectedDistrictId;
  String? _selectedVillageId;
  String? _profileLookupError;
  List<DistrictInfo> _districts = const [];
  BootstrapData? _bootstrap;
  ChwProfile? _chwProfile;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProfile;
    _nameController = TextEditingController(text: initial?.fullName ?? '');
    _employeeController = TextEditingController(text: initial?.employeeId ?? '');
    _phoneController = TextEditingController(text: initial?.phoneNumber ?? '');
    _villageSearchController =
        TextEditingController(text: initial?.primaryVillage ?? '');
    _designation = initial?.designation;
    _selectedDistrictId = initial?.districtId;
    _selectedVillageId = initial?.primaryVillageId;

    for (final controller in [
      _nameController,
      _employeeController,
      _phoneController,
      _villageSearchController,
    ]) {
      controller.addListener(_handleFieldChanged);
    }

    _loadDistrictsAndContext();
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _employeeController,
      _phoneController,
      _villageSearchController,
    ]) {
      controller.removeListener(_handleFieldChanged);
      controller.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadDistrictsAndContext() async {
    final districts = await _repository.loadAvailableDistricts();
    BootstrapData? bootstrap;
    final selectedDistrictId =
        _selectedDistrictId ?? (districts.isNotEmpty ? districts.first.id : null);

    if (selectedDistrictId != null) {
      try {
        bootstrap = await _repository.fetchBootstrapForDistrict(selectedDistrictId);
      } catch (_) {
        bootstrap = await _repository.loadCachedBootstrap();
      }
    }

    if (!mounted) return;
    setState(() {
      _districts = districts;
      _bootstrap = bootstrap;
      _selectedDistrictId = selectedDistrictId;
      _isLoadingDistricts = false;
    });

    final employeeId = _normalizedEmployeeId;
    if (employeeId.isNotEmpty) {
      await _resolveChwProfile(employeeId, silent: true);
    }
  }

  String get _normalizedEmployeeId =>
      _employeeController.text.trim().toUpperCase().replaceAll(' ', '');

  bool _isCurrentStepValid() {
    switch (_pageIndex) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return RegExp(r'^VR-\d{4}$').hasMatch(_normalizedEmployeeId);
      case 2:
        return _phoneController.text.trim().isNotEmpty;
      case 3:
        return _designation != null;
      case 4:
        return _selectedDistrictId != null && _selectedDistrictId!.isNotEmpty;
      case 5:
        return _selectedVillageId != null && _selectedVillageId!.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _goNext() async {
    if (!_isCurrentStepValid()) return;

    if (_pageIndex == 1) {
      final found = await _resolveChwProfile(_normalizedEmployeeId);
      if (!found) return;
    }

    if (_pageIndex == 4) {
      await _loadBootstrapForSelectedDistrict();
    }

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
    setState(() => _pageIndex = nextIndex);
  }

  Future<bool> _resolveChwProfile(String employeeId, {bool silent = false}) async {
    setState(() {
      _isLoadingProfile = true;
      _profileLookupError = null;
    });

    try {
      final profile = await _repository.lookupProfile(employeeId);
      if (!mounted) return false;
      if (profile == null) {
        setState(() {
          _chwProfile = null;
          _selectedVillageId = null;
          _profileLookupError = 'ashaIntroInvalidChwId'.tr(args: [employeeId]);
          _isLoadingProfile = false;
        });
        return false;
      }

      final matchedVillage = profile.block.villages.where((village) {
        return village.id == _selectedVillageId ||
            village.name.toLowerCase() ==
                _villageSearchController.text.trim().toLowerCase();
      }).toList();

      setState(() {
        _chwProfile = profile;
        _selectedVillageId = matchedVillage.isNotEmpty
            ? matchedVillage.first.id
            : (_selectedVillageId?.isNotEmpty == true
                ? _selectedVillageId
                : profile.block.villages.firstOrNull?.id);
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = profile.name;
        }
        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = profile.phone;
        }
        if (_selectedVillageId != null) {
          final village = profile.block.villages.firstWhere(
            (item) => item.id == _selectedVillageId,
            orElse: () => profile.block.villages.first,
          );
          _villageSearchController.text = village.name;
        }
        _profileLookupError = null;
        _isLoadingProfile = false;
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ashaIntroChwMatched'.tr(args: [profile.name, profile.block.name]),
            ),
          ),
        );
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _chwProfile = null;
        _selectedVillageId = null;
        _profileLookupError = 'ashaIntroProfileOffline'.tr();
        _isLoadingProfile = false;
      });
      return false;
    }
  }

  Future<void> _loadBootstrapForSelectedDistrict() async {
    final districtId = _selectedDistrictId;
    if (districtId == null || districtId.isEmpty) return;
    try {
      final bootstrap = await _repository.fetchBootstrapForDistrict(districtId);
      if (!mounted) return;
      setState(() => _bootstrap = bootstrap);
    } catch (_) {
      final cached = await _repository.loadCachedBootstrap();
      if (!mounted) return;
      if (cached != null) {
        setState(() => _bootstrap = cached);
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    final selectedDistrict = _districts.firstWhere(
      (item) => item.id == _selectedDistrictId,
      orElse: () => _bootstrap?.district ??
          const DistrictInfo(id: '', name: '', state: ''),
    );
    final selectedVillage = _availableVillages.firstWhere(
      (item) => item.id == _selectedVillageId,
      orElse: () => const ChwVillage(id: '', name: '', lat: 0, lng: 0),
    );

    setState(() => _isSaving = true);
    final profile = AshaWorkerProfile(
      fullName: _nameController.text.trim(),
      employeeId: _normalizedEmployeeId,
      phoneNumber: _phoneController.text.trim(),
      designation: _designation ?? 'ASHA',
      districtId: selectedDistrict.id,
      districtName: selectedDistrict.name,
      districtState: selectedDistrict.state,
      blockId: _chwProfile?.block.id ?? widget.initialProfile?.blockId ?? '',
      blockName: _chwProfile?.block.name ?? widget.initialProfile?.blockName ?? '',
      primaryVillageId: selectedVillage.id,
      primaryVillage: selectedVillage.name,
      profileImagePath: widget.initialProfile?.profileImagePath,
    );
    await _profileRepository.saveProfile(profile);
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

  List<ChwVillage> get _availableVillages {
    final villages = _chwProfile?.block.villages ?? const <ChwVillage>[];
    final query = _villageSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return villages;
    return villages
        .where((village) => village.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _QuestionStep(
        title: 'ashaIntroNameTitle'.tr(),
        subtitle: 'ashaIntroNameSubtitle'.tr(),
        child: _StyledTextField(
          controller: _nameController,
          hintText: 'Seema Devi',
        ),
      ),
      _QuestionStep(
        title: 'ashaIntroChwTitle'.tr(),
        subtitle: 'ashaIntroChwSubtitle'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StyledTextField(
              controller: _employeeController,
              hintText: 'VR-2841',
              textCapitalization: TextCapitalization.characters,
            ),
            if (_profileLookupError != null) ...[
              const SizedBox(height: 12),
              Text(
                _profileLookupError!,
                style: const TextStyle(
                  color: Color(0xFFB14040),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      _QuestionStep(
        title: 'ashaIntroPhoneTitle'.tr(),
        subtitle: 'ashaIntroPhoneSubtitle'.tr(),
        child: _StyledTextField(
          controller: _phoneController,
          hintText: '+91 90000 12345',
          keyboardType: TextInputType.phone,
        ),
      ),
      _QuestionStep(
        title: 'ashaIntroRoleTitle'.tr(),
        subtitle: 'ashaIntroRoleSubtitle'.tr(),
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
        title: 'ashaIntroDistrictTitle'.tr(),
        subtitle: _chwProfile == null
            ? 'ashaIntroDistrictSubtitle'.tr()
            : 'ashaIntroDistrictMatchedSubtitle'
                .tr(args: [_chwProfile!.block.name]),
        child: _isLoadingDistricts
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: _districts
                    .map(
                      (district) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SelectionCard(
                          title: district.name,
                          subtitle: district.state,
                          isSelected: _selectedDistrictId == district.id,
                          onTap: () => setState(() => _selectedDistrictId = district.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      _QuestionStep(
        title: 'ashaIntroVillageTitle'.tr(),
        subtitle: _chwProfile == null
            ? 'ashaIntroVillageSubtitle'.tr()
            : 'ashaIntroVillageMatchedSubtitle'
                .tr(args: [_chwProfile!.name, _chwProfile!.block.name]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StyledTextField(
              controller: _villageSearchController,
              hintText: 'ashaIntroVillageHint'.tr(),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9E1EB)),
              ),
              child: _availableVillages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _chwProfile == null
                              ? 'ashaIntroVillageLoadFirst'.tr()
                              : 'ashaIntroVillageNoMatch'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF617087),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _availableVillages.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFE7EAF0)),
                      itemBuilder: (context, index) {
                        final village = _availableVillages[index];
                        return ListTile(
                          title: Text(village.name),
                          subtitle: Text(_chwProfile?.block.name ?? ''),
                          trailing: _selectedVillageId == village.id
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2368AF),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedVillageId = village.id;
                              _villageSearchController.text = village.name;
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ];

    final canProceed = _isCurrentStepValid() &&
        !_isSaving &&
        (_pageIndex != 1 || !_isLoadingProfile);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF2368AF)),
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
                          child: Text('ashaBack'.tr()),
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
                        child: Text(
                          _isSaving
                              ? 'ashaSaving'.tr()
                              : _pageIndex == steps.length - 1
                                  ? 'ashaFinishSetup'.tr()
                                  : _isLoadingProfile && _pageIndex == 1
                                      ? 'ashaChecking'.tr()
                                      : 'continueButton'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
          color:
              isSelected ? const Color(0xFFE5F0FB) : const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2368AF) : const Color(0xFFD9E1EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isSelected ? const Color(0xFF2368AF) : const Color(0xFF425268),
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFFEAF3FF) : const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2368AF) : const Color(0xFFD9E1EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18314F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF617087),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2368AF),
              ),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
