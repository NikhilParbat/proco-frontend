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
  // ─── Theme colors (matching UpdateProfilePage) ───────────────────────────
  static const Color _bg = Color(0xFF040326);
  static const Color _card = Color(0xFF08979F);
  static const Color _accent = Color(0xFF0BBFCA);
  static const Color _white = Colors.white;

  // ─── Data ─────────────────────────────────────────────────────────────────
  final List<String> options = List.from(kDomains);
  final Map<String, bool> opportunityTypes = {
    for (final t in kOpportunityTypes) t: false,
  };

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
  bool _isLoading = true;

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

  void _applyFilterToState(GetFilterRes existing) {
    selectedOptions.clear();
    selectedOptions.addAll(existing.selectedOptions);

    for (final selected in existing.selectedOptions) {
      if (!options.contains(selected)) options.add(selected);
    }
    for (final custom in existing.customOptions) {
      if (!options.contains(custom)) options.add(custom);
    }

    for (final key in existing.opportunityTypes.keys) {
      if (opportunityTypes.containsKey(key)) {
        opportunityTypes[key] = existing.opportunityTypes[key] ?? false;
      }
    }

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

    final activeJson = prefs.getString('activeFilter');
    if (activeJson != null) {
      try {
        final active = getFilterResFromJson(activeJson);
        setState(() => _applyFilterToState(active));
        if (filterNotifier.activeFilter == null) {
          filterNotifier.setActiveFilter(active);
        }
        setState(() => _isLoading = false);
        return;
      } catch (_) {}
    }

    final userId = prefs.getString('userId') ?? '';
    if (userId.isNotEmpty) {
      try {
        final existing = await FilterHelper.getFilter(userId);
        if (!mounted) return;
        setState(() => _applyFilterToState(existing));
        filterNotifier.setActiveFilter(existing);
      } catch (_) {}
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _white,
            size: 20,
          ),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Domain ──────────────────────────────────────────────
                  _sectionLabel('Domain'),
                  SizedBox(height: 12.h),
                  _domainChips(),
                  if (showCustomInput) ...[
                    SizedBox(height: 10.h),
                    _customDomainInput(),
                  ],
                  SizedBox(height: 24.h),

                  // ── Opportunity Type ────────────────────────────────────
                  _sectionLabel('Opportunity Type'),
                  SizedBox(height: 12.h),
                  _opportunityToggles(),
                  SizedBox(height: 24.h),

                  // ── Skills / Technologies ───────────────────────────────
                  _sectionLabel('Skills / Technologies'),
                  SizedBox(height: 12.h),
                  _skillsInput(),
                  if (selectedSkills.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    _skillsChips(),
                  ],
                  SizedBox(height: 24.h),

                  // ── Location ────────────────────────────────────────────
                  _sectionLabel('Location'),
                  SizedBox(height: 12.h),
                  _locationToggles(),
                  SizedBox(height: 12.h),
                  if (selectedLocationOption == 'City') _cityField(),
                  if (selectedLocationOption == 'State') _stateDropdown(),
                  if (selectedLocationOption == 'Country') _countryField(),
                  SizedBox(height: 24.h),

                  // ── Sort by Latest ──────────────────────────────────────
                  _sectionLabel('Sort & Recency'),
                  SizedBox(height: 12.h),
                  _sortByLatestToggle(),
                  SizedBox(height: 16.h),
                  _postedWithinChips(),
                  SizedBox(height: 32.h),

                  // ── Submit ──────────────────────────────────────────────
                  _applyButton(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
    );
  }

  // ─── Section label (same as UpdateProfilePage) ────────────────────────────
  Widget _sectionLabel(String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Container(height: 1, color: _card.withValues(alpha:0.5)),
      ],
    );
  }

  // ─── Domain chips ─────────────────────────────────────────────────────────
  Widget _domainChips() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: _card.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha:0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected
                      ? selectedOptions.remove(option)
                      : selectedOptions.add(option);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected ? _card : _card.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _accent : _card.withValues(alpha:0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded, size: 13, color: _white),
                      SizedBox(width: 4.w),
                    ],
                    Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? _white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // CUSTOM bubble
          GestureDetector(
            onTap: () => setState(() => showCustomInput = true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha:0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 14, color: _accent),
                  SizedBox(width: 4.w),
                  const Text(
                    'CUSTOM',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customDomainInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: customControllers[0],
            style: const TextStyle(color: _white, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Enter custom domain',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
              prefixIcon: const Icon(
                Icons.edit_outlined,
                color: _accent,
                size: 20,
              ),
              filled: true,
              fillColor: _card.withValues(alpha:0.25),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () {
            final text = customControllers[0].text.trim();
            if (text.isNotEmpty) {
              setState(() {
                options.add(text);
                selectedOptions.add(text);
                showCustomInput = false;
                customControllers[0].clear();
              });
            }
          },
          child: Container(
            height: 52.h,
            width: 52.h,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_rounded, color: _white, size: 22),
          ),
        ),
      ],
    );
  }

  // ─── Opportunity type toggles ─────────────────────────────────────────────
  Widget _opportunityToggles() {
    return Container(
      decoration: BoxDecoration(
        color: _card.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha:0.3)),
      ),
      child: Column(
        children: opportunityTypes.keys.toList().asMap().entries.map((e) {
          final idx = e.key;
          final opportunity = e.value;
          final isLast = idx == opportunityTypes.length - 1;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline_rounded,
                          color: opportunityTypes[opportunity]!
                              ? _accent
                              : Colors.white38,
                          size: 18,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          opportunity,
                          style: TextStyle(
                            color: opportunityTypes[opportunity]!
                                ? _white
                                : Colors.white60,
                            fontSize: 15,
                            fontWeight: opportunityTypes[opportunity]!
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: opportunityTypes[opportunity]!,
                      activeThumbColor: _accent,
                      activeTrackColor: _card.withValues(alpha:0.6),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white12,
                      onChanged: (value) =>
                          setState(() => opportunityTypes[opportunity] = value),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: _card.withValues(alpha:0.3),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Skills input ─────────────────────────────────────────────────────────
  Widget _skillsInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _skillInputController,
            style: const TextStyle(color: _white, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Add a skill or technology',
              hintText: 'e.g. React, Python…',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              prefixIcon: const Icon(
                Icons.psychology_outlined,
                color: _accent,
                size: 20,
              ),
              filled: true,
              fillColor: _card.withValues(alpha:0.25),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: () {
            final val = _skillInputController.text.trim();
            if (val.isNotEmpty && !selectedSkills.contains(val)) {
              setState(() {
                selectedSkills.add(val);
                _skillInputController.clear();
              });
            }
          },
          child: Container(
            height: 54.h,
            width: 54.h,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded, color: _white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _skillsChips() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: _card.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha:0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: selectedSkills.map((skill) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: () => setState(() => selectedSkills.remove(skill)),
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
    );
  }

  // ─── Location ─────────────────────────────────────────────────────────────
  Widget _locationToggles() {
    return Container(
      decoration: BoxDecoration(
        color: _card.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha:0.3)),
      ),
      child: Row(
        children: ['City', 'State', 'Country'].map((option) {
          final isActive = selectedLocationOption == option;
          final isLast = option == 'Country';
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(
                () => selectedLocationOption = isActive ? '' : option,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 13.h),
                decoration: BoxDecoration(
                  color: isActive ? _card : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: option == 'City'
                        ? const Radius.circular(14)
                        : Radius.zero,
                    right: isLast ? const Radius.circular(14) : Radius.zero,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option == 'City'
                          ? Icons.location_city_outlined
                          : option == 'State'
                          ? Icons.map_outlined
                          : Icons.flag_outlined,
                      size: 16,
                      color: isActive ? _white : Colors.white38,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      option,
                      style: TextStyle(
                        color: isActive ? _white : Colors.white38,
                        fontSize: 13,
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
    );
  }

  Widget _cityField() {
    return TextFormField(
      controller: _cityController,
      style: const TextStyle(color: _white, fontSize: 15),
      onChanged: (v) => setState(() => selectedCity = v),
      decoration: InputDecoration(
        labelText: 'City name',
        hintText: 'e.g. San Francisco',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: _accent,
          size: 20,
        ),
        filled: true,
        fillColor: _card.withValues(alpha:0.25),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedState.isEmpty ? null : selectedState,
      dropdownColor: const Color(0xFF0A0540),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      style: const TextStyle(color: _white, fontSize: 15),
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(
        labelText: 'State',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        prefixIcon: const Icon(Icons.map_outlined, color: _accent, size: 20),
        filled: true,
        fillColor: _card.withValues(alpha:0.25),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
      hint: const Text(
        'Choose a state',
        style: TextStyle(color: Colors.white38),
      ),
      items: states
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(color: _white)),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => selectedState = v!),
    );
  }

  Widget _countryField() {
    return TextFormField(
      controller: _countryController,
      style: const TextStyle(color: _white, fontSize: 15),
      onChanged: (v) => setState(() => selectedCountry = v),
      decoration: InputDecoration(
        labelText: 'Country name',
        hintText: 'e.g. United States',
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
        prefixIcon: const Icon(Icons.flag_outlined, color: _accent, size: 20),
        filled: true,
        fillColor: _card.withValues(alpha:0.25),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _card.withValues(alpha:0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  // ─── Sort & Recency ───────────────────────────────────────────────────────
  Widget _sortByLatestToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _card.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _card.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: sortByTime ? _accent : Colors.white38,
                size: 18,
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort by Latest',
                    style: TextStyle(
                      color: sortByTime ? _white : Colors.white60,
                      fontSize: 15,
                      fontWeight: sortByTime
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'Show newest jobs first',
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: sortByTime,
            activeThumbColor: _accent,
            activeTrackColor: _card.withValues(alpha:0.6),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            onChanged: (val) => setState(() => sortByTime = val),
          ),
        ],
      ),
    );
  }

  Widget _postedWithinChips() {
    const entries = [('24h', '24 Hours'), ('7d', '7 Days'), ('30d', '30 Days')];
    return Row(
      children: entries.map((entry) {
        final isSelected = postedWithin == entry.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => postedWithin = isSelected ? '' : entry.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: entry.$1 == '30d' ? 0 : 8.w),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected ? _card : _card.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _accent : _card.withValues(alpha:0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    entry.$1 == '24h'
                        ? Icons.flash_on_rounded
                        : entry.$1 == '7d'
                        ? Icons.calendar_today_outlined
                        : Icons.calendar_month_outlined,
                    color: isSelected ? _white : Colors.white38,
                    size: 18,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    entry.$2,
                    style: TextStyle(
                      color: isSelected ? _white : Colors.white38,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
          opportunityTypes: opportunityTypes,
          selectedLocationOption: selectedLocationOption,
          selectedCity: selectedCity,
          selectedState: selectedState,
          selectedCountry: selectedCountry,
          customOptions: customInput,
          skills: List.from(selectedSkills),
          sortByTime: sortByTime,
          postedWithin: postedWithin,
        );

        if (!context.mounted) return;

        final filterNotifier = Provider.of<FilterNotifier>(
          // ignore: use_build_context_synchronously
          context,
          listen: false,
        );

        await filterNotifier.createFilter(userId!, filterData);

        if (!context.mounted) return;

        filterNotifier.setActiveFilter(
          GetFilterRes(
            id: '',
            selectedOptions: List.from(selectedOptions),
            opportunityTypes: Map.from(opportunityTypes),
            selectedLocationOption: selectedLocationOption,
            selectedCity: selectedCity,
            selectedState: selectedState,
            selectedCountry: selectedCountry,
            customOptions: customInput,
            skills: List.from(selectedSkills),
            sortByTime: sortByTime,
            postedWithin: postedWithin,
          ),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _card.withValues(alpha:0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Apply Filters',
            style: TextStyle(
              color: _white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
