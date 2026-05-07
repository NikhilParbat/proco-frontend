import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/models/request/filters/create_filter.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/filter_helper.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  static const Color _theme = kThemeColor;
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _grey = Color(0xFF9E9E9E);
  static const Color _border = Color(0xFFE0E0E0);

  // ─── Data ──────────────────────────────────────────────────────────────────
  final List<String> options = List.from(kDomains);

  bool _internship = false;
  bool _research = false;
  bool _freelance = false;
  bool _competition = false;
  bool _collaborate = false;

  List<TextEditingController> customControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _skillInputController = TextEditingController();

  final List<String> selectedOptions = [];
  final List<String> selectedSkills = [];
  bool showCustomInput = false;
  bool sortByTime = false;
  String postedWithin = '';
  String selectedLocationOption = '';
  String selectedCity = '';
  String selectedState = '';
  String selectedCountry = '';
  double _radiusKm = 25;
  bool _isLoading = true;

  final List<String> states = [
    "California",
    "Texas",
    "Florida",
    "New York",
    "Illinois",
    "Pennsylvania",
    "Ohio",
    "Georgia",
    "North Carolina",
    "Michigan",
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingFilter();
  }

  @override
  void dispose() {
    for (final c in customControllers) {
      c.dispose();
    }
    _cityController.dispose();
    _countryController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      selectedOptions.clear();
      _internship = false;
      _research = false;
      _freelance = false;
      _competition = false;
      _collaborate = false;
      selectedLocationOption = '';
      selectedCity = '';
      selectedState = '';
      selectedCountry = '';
      _cityController.clear();
      _countryController.clear();
      selectedSkills.clear();
      sortByTime = false;
      postedWithin = '';
      _radiusKm = 25;
      showCustomInput = false;
    });
  }

  void _applyFilterToState(GetFilterRes existing) {
    selectedOptions.clear();
    selectedOptions.addAll(existing.selectedOptions);

    for (final selected in existing.selectedOptions) {
      if (!options.contains(selected)) options.add(selected);
    }
    for (final custom in existing.customOptions) {
      if (!options.contains(custom)) options.add(custom);
      if (!selectedOptions.contains(custom)) selectedOptions.add(custom);
    }

    _internship = existing.internship;
    _research = existing.research;
    _freelance = existing.freelance;
    _competition = existing.competition;
    _collaborate = existing.collaborate;

    selectedLocationOption = existing.selectedLocationOption;
    selectedCity = existing.selectedCity;
    selectedState = existing.selectedState;
    selectedCountry = existing.selectedCountry;
    _cityController.text = existing.selectedCity;
    _countryController.text = existing.selectedCountry;

    selectedSkills.clear();
    selectedSkills.addAll(existing.skills);

    sortByTime = existing.sortByTime;
    postedWithin = existing.postedWithin;
  }

  Future<void> _loadExistingFilter() async {
    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Load from local cache immediately so the page renders fast
    final activeJson = prefs.getString('activeFilter');
    if (activeJson != null) {
      try {
        final active = getFilterResFromJson(activeJson);
        setState(() {
          _applyFilterToState(active);
          _isLoading = false;
        });
        if (filterNotifier.activeFilter == null) {
          filterNotifier.setActiveFilter(active);
        }
      } catch (_) {}
    }

    // Always refresh from backend to stay in sync across sessions
    final userId = prefs.getString('userId') ?? '';
    if (userId.isNotEmpty) {
      final response = await FilterHelper.getFilter(userId);
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() => _applyFilterToState(response.data!));
        filterNotifier.setActiveFilter(response.data!);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: _dark, size: 22),
        ),
        centerTitle: true,
        title: Text(
          'Filters',
          style: TextStyle(
            fontFamily: kFontDMSans,
            color: _dark,
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(
              'Reset All',
              style: TextStyle(
                fontFamily: kFontDMSans,
                color: _theme,
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _theme))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── CORE FILTERS ──────────────────────────────────────────
                  _sectionLabel('Core Filters'),
                  SizedBox(height: 14.h),
                  _fieldLabel('Domain'),
                  SizedBox(height: 8.h),
                  _domainChips(),
                  if (showCustomInput) ...[
                    SizedBox(height: 10.h),
                    _customDomainInput(),
                  ],
                  SizedBox(height: 20.h),
                  _fieldLabel('Location'),
                  SizedBox(height: 8.h),
                  _locationSection(),
                  SizedBox(height: 24.h),

                  // ── OPPORTUNITY TYPE ──────────────────────────────────────
                  _sectionLabel('Opportunity Type'),
                  SizedBox(height: 14.h),
                  _opportunityChips(),
                  SizedBox(height: 24.h),

                  // ── UPLOAD TIME ───────────────────────────────────────────
                  _sectionLabel('Upload Time'),
                  SizedBox(height: 14.h),
                  _postedWithinChips(),
                  SizedBox(height: 24.h),

                  // ── TECHNICAL & REWARDS ───────────────────────────────────
                  _sectionLabel('Technical & Rewards'),
                  SizedBox(height: 14.h),
                  _fieldLabel('Skills'),
                  SizedBox(height: 8.h),
                  _skillsSection(),
                  SizedBox(height: 20.h),
                  _sortByLatestRow(),
                  SizedBox(height: 32.h),

                  // ── Apply ─────────────────────────────────────────────────
                  _applyButton(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
    );
  }

  // ─── Section / field labels ───────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: kFontDMSans,
        color: _grey,
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontDMSans,
        color: _dark,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ─── Shared chip widget ───────────────────────────────────────────────────
  Widget _chip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? _theme : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSelected ? _theme : _border,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: kFontDMSans,
          color: isSelected ? Colors.white : _dark,
          fontSize: 13.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // ─── Styled text field ────────────────────────────────────────────────────
  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: _dark, fontSize: 14.sp),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _grey, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _theme, width: 1.5),
        ),
      ),
    );
  }

  // ─── Domain chips ─────────────────────────────────────────────────────────
  Widget _domainChips() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected
                    ? selectedOptions.remove(option)
                    : selectedOptions.add(option);
              }),
              child: _chip(option, isSelected),
            );
          }),
          // "Other" chip — toggles the custom-input row
          GestureDetector(
            onTap: () => setState(() => showCustomInput = !showCustomInput),
            child: _chip('Other', showCustomInput),
          ),
        ],
      ),
    );
  }

  Widget _customDomainInput() {
    return Row(
      children: [
        Expanded(
          child: _styledTextField(
            controller: customControllers[0],
            hint: 'Type your domain and press ✓',
            icon: Icons.edit_outlined,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitCustomDomain(),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: _submitCustomDomain,
          child: Container(
            height: 52.h,
            width: 52.h,
            decoration: BoxDecoration(
              color: customControllers[0].text.trim().isNotEmpty
                  ? _theme
                  : _border,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  void _submitCustomDomain() {
    final text = customControllers[0].text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!options.contains(text)) options.add(text);
      if (!selectedOptions.contains(text)) selectedOptions.add(text);
      customControllers[0].clear();
      showCustomInput = false;
    });
  }

  // ─── Opportunity type chips ────────────────────────────────────────────────
  Widget _opportunityChips() {
    final entries = [
      ('Competition', _competition, (bool v) => setState(() => _competition = v)),
      ('Collaboration', _collaborate, (bool v) => setState(() => _collaborate = v)),
      ('Research', _research, (bool v) => setState(() => _research = v)),
      ('Freelance', _freelance, (bool v) => setState(() => _freelance = v)),
      ('Internship', _internship, (bool v) => setState(() => _internship = v)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final (label, isSelected, setter) = e;
        return GestureDetector(
          onTap: () => setter(!isSelected),
          child: _chip(label, isSelected),
        );
      }).toList(),
    );
  }

  // ─── Location section ─────────────────────────────────────────────────────
  Widget _locationSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: ['City', 'State', 'Country'].map((opt) {
              final isActive = selectedLocationOption == opt;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => selectedLocationOption = isActive ? '' : opt,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                      color: isActive ? _theme : Colors.transparent,
                      borderRadius: BorderRadius.horizontal(
                        left: opt == 'City'
                            ? const Radius.circular(11)
                            : Radius.zero,
                        right: opt == 'Country'
                            ? const Radius.circular(11)
                            : Radius.zero,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt == 'City'
                              ? Icons.location_city_outlined
                              : opt == 'State'
                              ? Icons.map_outlined
                              : Icons.flag_outlined,
                          size: 15,
                          color: isActive ? Colors.white : _grey,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          opt,
                          style: TextStyle(
                            fontFamily: kFontDMSans,
                            color: isActive ? Colors.white : _grey,
                            fontSize: 13.sp,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (selectedLocationOption == 'City') ...[
          SizedBox(height: 10.h),
          _styledTextField(
            controller: _cityController,
            hint: 'Enter city name',
            icon: Icons.location_on_outlined,
            onChanged: (v) => setState(() => selectedCity = v),
          ),
          SizedBox(height: 10.h),
          _kmSlider(),
        ],
        if (selectedLocationOption == 'State') ...[
          SizedBox(height: 10.h),
          _stateDropdown(),
        ],
        if (selectedLocationOption == 'Country') ...[
          SizedBox(height: 10.h),
          _styledTextField(
            controller: _countryController,
            hint: 'Enter country name',
            icon: Icons.flag_outlined,
            onChanged: (v) => setState(() => selectedCountry = v),
          ),
        ],
      ],
    );
  }

  Widget _kmSlider() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Radius',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  color: _dark,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _theme.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_radiusKm.round()} km',
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    color: _theme,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _theme,
              inactiveTrackColor: _border,
              thumbColor: _theme,
              overlayColor: _theme.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 3,
            ),
            child: Slider(
              value: _radiusKm,
              min: 1,
              max: 200,
              divisions: 40,
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 km',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  color: _grey,
                  fontSize: 11.sp,
                ),
              ),
              Text(
                '200 km',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  color: _grey,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedState.isEmpty ? null : selectedState,
      dropdownColor: Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: _grey),
      style: TextStyle(color: _dark, fontSize: 14.sp),
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(
        hintText: 'Choose a state',
        hintStyle: TextStyle(color: _grey, fontSize: 14.sp),
        prefixIcon: Icon(Icons.map_outlined, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _theme, width: 1.5),
        ),
      ),
      items: states
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle(color: _dark, fontSize: 14.sp)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedState = v!),
    );
  }

  // ─── Skills ───────────────────────────────────────────────────────────────
  Widget _skillsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedSkills.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedSkills.map((skill) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _theme,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skill,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () =>
                            setState(() => selectedSkills.remove(skill)),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputController,
                  style: TextStyle(color: _dark, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'Add another skill...',
                    hintStyle: TextStyle(color: _grey, fontSize: 14.sp),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _addSkill,
                ),
              ),
              GestureDetector(
                onTap: () => _addSkill(_skillInputController.text),
                child: Icon(Icons.add_circle_outline, color: _theme, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addSkill(String val) {
    val = val.trim();
    if (val.isNotEmpty && !selectedSkills.contains(val)) {
      setState(() {
        selectedSkills.add(val);
        _skillInputController.clear();
      });
    }
  }

  // ─── Posted within chips ──────────────────────────────────────────────────
  Widget _postedWithinChips() {
    const entries = [
      ('7d', 'Past Week'),
      ('15d', '15 Days'),
      ('30d', '1 Month'),
      ('90d', '3 Months'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        final isSelected = postedWithin == entry.$1;
        return GestureDetector(
          onTap: () =>
              setState(() => postedWithin = isSelected ? '' : entry.$1),
          child: _chip(entry.$2, isSelected),
        );
      }).toList(),
    );
  }

  // ─── Sort by Latest ───────────────────────────────────────────────────────
  Widget _sortByLatestRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sort by Latest',
            style: TextStyle(
              fontFamily: kFontDMSans,
              color: _dark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: sortByTime,
            activeThumbColor: _theme,
            inactiveThumbColor: _grey,
            inactiveTrackColor: _border,
            onChanged: (val) => setState(() => sortByTime = val),
          ),
        ],
      ),
    );
  }

  // ─── Apply button ─────────────────────────────────────────────────────────
  Widget _applyButton() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        final customInput = customControllers
            .map((c) => c.text)
            .where((t) => t.isNotEmpty)
            .toList();

        final filterData = CreateFilterRequest(
          agentId: userId ?? '',
          selectedOptions: selectedOptions,
          selectedLocationOption: selectedLocationOption,
          selectedCity: selectedCity,
          selectedState: selectedState,
          selectedCountry: selectedCountry,
          customOptions: customInput,
          skills: List.from(selectedSkills),
          sortByTime: sortByTime,
          postedWithin: postedWithin,
          internship: _internship,
          research: _research,
          freelance: _freelance,
          competition: _competition,
          collaborate: _collaborate,
        );

        if (!context.mounted) return;

        final filterNotifier = Provider.of<FilterNotifier>(
          // ignore: use_build_context_synchronously
          context,
          listen: false,
        );

        final success = await filterNotifier.createFilter(userId!, filterData);

        if (!context.mounted) return;
        if (!success) return;

        final savedFilter =
            filterNotifier.filter ??
            GetFilterRes(
              id: '',
              selectedOptions: List.from(selectedOptions),
              selectedLocationOption: selectedLocationOption,
              selectedCity: selectedCity,
              selectedState: selectedState,
              selectedCountry: selectedCountry,
              customOptions: customInput,
              skills: List.from(selectedSkills),
              sortByTime: sortByTime,
              postedWithin: postedWithin,
              internship: _internship,
              research: _research,
              freelance: _freelance,
              competition: _competition,
              collaborate: _collaborate,
            );

        filterNotifier.setActiveFilter(savedFilter);

        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: _theme,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Apply Filters',
            style: TextStyle(
              fontFamily: kFontDMSans,
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
