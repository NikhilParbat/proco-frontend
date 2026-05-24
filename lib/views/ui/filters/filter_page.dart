import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/filter_provider.dart';
import 'package:proco/models/request/filters/create_filter.dart';
import 'package:proco/models/response/filters/get_filter.dart';
import 'package:proco/services/helpers/filter_helper.dart';
import 'package:proco/services/helpers/user_helper.dart';
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

  // ─── Static UI Options ─────────────────────────────────────────────────────
  final List<String> options = List.from(kDomains);
  final List<String> availableOpportunityTypes = [
    "Competition",
    "Collaborate",
    "Research",
    "Freelance",
    "Internship"
  ];

  // ─── State Management Data Structures ──────────────────────────────────────
  final List<String> selectedDomains = [];
  final List<String> opportunityTypes = [];
  final List<String> selectedSkills = [];
  
  List<TextEditingController> customControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );
  final TextEditingController _skillInputController = TextEditingController();

  bool showCustomInput = false;
  bool sortByTime = false;
  String postedWithin = '';
  String selectedLocationOption = '';
  String selectedCity = '';
  String selectedState = '';
  String selectedCountry = '';
  double _radiusKm = 25;
  String _profileLocationLabel = 'Your profile location';
  bool _isLoading = true;

  // ─── 1. Location Data Collections ─────────────────────────────────────────
  final TextEditingController _cityController = TextEditingController();

  final List<String> states = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", 
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", 
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", 
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", 
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu", 
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
  ];

  final List<String> countries = [
    "Afghanistan", "Albania", "Algeria", "Andorra", "Angola", "Antigua and Barbuda", 
    "Argentina", "Armenia", "Australia", "Austria", "Azerbaijan", "Bahamas", "Bahrain", 
    "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan", 
    "Bolivia", "Bosnia and Herzegovina", "Botswana", "Brazil", "Brunei", "Bulgaria", 
    "Burkina Faso", "Burundi", "Cabo Verde", "Cambodia", "Cameroon", "Canada", 
    "Central African Republic", "Chad", "Chile", "China", "Colombia", "Comoros", 
    "Congo (Congo-Brazzaville)", "Costa Rica", "Croatia", "Cuba", "Cyprus", 
    "Czechia (Czech Republic)", "Denmark", "Djibouti", "Dominica", "Dominican Republic", 
    "Ecuador", "Egypt", "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", 
    "Eswatini", "Ethiopia", "Fiji", "Finland", "France", "Gabon", "Gambia", "Georgia", 
    "Germany", "Ghana", "Greece", "Grenada", "Guatemala", "Guinea", "Guinea-Bissau", 
    "Guyana", "Haiti", "Holy See", "Honduras", "Hungary", "Iceland", "India", 
    "Indonesia", "Iran", "Iraq", "Ireland", "Israel", "Italy", "Jamaica", "Japan", 
    "Jordan", "Kazakhstan", "Kenya", "Kiribati", "Kuwait", "Kyrgyzstan", "Laos", 
    "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein", "Lithuania", 
    "Luxembourg", "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", 
    "Marshall Islands", "Mauritania", "Mauritius", "Mexico", "Micronesia", "Moldova", 
    "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique", "Myanmar (Burma)", 
    "Namibia", "Nauru", "Nepal", "Netherlands", "New Zealand", "Nicaragua", "Niger", 
    "Nigeria", "North Korea", "North Macedonia", "Norway", "Oman", "Pakistan", 
    "Palau", "Palestine State", "Panama", "Papua New Guinea", "Paraguay", "Peru", 
    "Philippines", "Poland", "Portugal", "Qatar", "Romania", "Russia", "Rwanda", 
    "Saint Kitts and Nevis", "Saint Lucia", "Saint Vincent and the Grenadines", 
    "Samoa", "San Marino", "Sao Tome and Principe", "Saudi Arabia", "Senegal", 
    "Serbia", "Seychelles", "Sierra Leone", "Singapore", "Slovakia", "Slovenia", 
    "Solomon Islands", "Somalia", "South Africa", "South Korea", "South Sudan", 
    "Spain", "Sri Lanka", "Sudan", "Suriname", "Sweden", "Switzerland", "Syria", 
    "Tajikistan", "Tanzania", "Thailand", "Timor-Leste", "Togo", "Tonga", 
    "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan", "Tuvalu", "Uganda", 
    "Ukraine", "United Arab Emirates", "United Kingdom", "United States of America", 
    "Uruguay", "Uzbekistan", "Vanuatu", "Venezuela", "Vietnam", "Yemen", "Zambia", "Zimbabwe"
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingFilter();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _skillInputController.dispose();
    for (final c in customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      selectedDomains.clear();
      opportunityTypes.clear();
      selectedLocationOption = '';
      _cityController.clear();
      selectedCity = '';
      selectedState = '';
      selectedCountry = '';
      selectedSkills.clear();
      sortByTime = false;
      postedWithin = '';
      _radiusKm = 25;
      showCustomInput = false;
    });
  }

  void _applyFilterToState(GetFilterRes existing) {
    selectedDomains.clear();
    selectedDomains.addAll(existing.selectedDomains);

    // Sync domain chip items list representation
    for (final domain in existing.selectedDomains) {
      if (!options.contains(domain)) options.add(domain);
    }

    opportunityTypes.clear();
    opportunityTypes.addAll(existing.opportunityTypes);

    selectedLocationOption = existing.selectedLocationOption;
    selectedCity = existing.selectedCity;
    _cityController.text = existing.selectedCity;
    selectedState = existing.selectedState;
    selectedCountry = existing.selectedCountry;
    _radiusKm = (existing.distanceKm > 0 ? existing.distanceKm.clamp(1, 60) : 25).toDouble();

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
        setState(() {
          _applyFilterToState(active);
          _isLoading = false;
        });
        if (filterNotifier.activeFilter == null) {
          filterNotifier.setActiveFilter(active);
        }
      } catch (_) {}
    }

    await _loadProfileLocation();

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

  Future<void> _loadProfileLocation() async {
    final response = await UserHelper.getProfile();
    if (!mounted || !response.success || response.data == null) return;

    final profile = response.data!;
    final parts = [
      profile.city?.trim() ?? '',
      profile.state?.trim() ?? '',
      profile.country?.trim() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      setState(() {
        _profileLocationLabel = parts.join(', ');
      });
    }
  }

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
          ? const Center(child: CircularProgressIndicator(color: _theme))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  _sectionLabel('Opportunity Type'),
                  SizedBox(height: 14.h),
                  _opportunityChips(),
                  SizedBox(height: 24.h),

                  _sectionLabel('Upload Time'),
                  SizedBox(height: 14.h),
                  _postedWithinChips(),
                  SizedBox(height: 24.h),

                  _sectionLabel('Technical & Rewards'),
                  SizedBox(height: 14.h),
                  _fieldLabel('Skills'),
                  SizedBox(height: 8.h),
                  _skillsSection(),
                  SizedBox(height: 20.h),
                  _sortByLatestRow(),
                  SizedBox(height: 32.h),

                  _applyButtonWidget(),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
    );
  }

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
            final isSelected = selectedDomains.contains(option);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected
                    ? selectedDomains.remove(option)
                    : selectedDomains.add(option);
              }),
              child: _chip(option, isSelected),
            );
          }),
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
      if (!selectedDomains.contains(text)) selectedDomains.add(text);
      customControllers[0].clear();
      showCustomInput = false;
    });
  }

  Widget _opportunityChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableOpportunityTypes.map((type) {
        final isSelected = opportunityTypes.contains(type);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? opportunityTypes.remove(type) : opportunityTypes.add(type);
          }),
          child: _chip(type, isSelected),
        );
      }).toList(),
    );
  }

  Widget _locationSection() {
    final bool showDistanceSlider =
        selectedLocationOption == '' || selectedLocationOption == 'City';

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
                        left: opt == 'City' ? const Radius.circular(11) : Radius.zero,
                        right: opt == 'Country' ? const Radius.circular(11) : Radius.zero,
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
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
            hint: 'Enter your target city...',
            icon: Icons.location_city_outlined,
            onChanged: (val) => selectedCity = val.trim(),
          ),
        ],
        if (selectedLocationOption == 'State') ...[
          SizedBox(height: 10.h),
          _stateDropdown(),
        ],
        if (selectedLocationOption == 'Country') ...[
          SizedBox(height: 10.h),
          _countryDropdown(),
        ],
        if (showDistanceSlider) ...[
          SizedBox(height: 10.h),
          _kmSlider(),
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
                'Distance (Your location)',
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
          SizedBox(height: 2.h),
          Text(
            _profileLocationLabel,
            style: TextStyle(
              fontFamily: kFontDMSans,
              color: _grey,
              fontSize: 11.sp,
            ),
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
              max: 60,
              divisions: 12,
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: TextStyle(fontFamily: kFontDMSans, color: _grey, fontSize: 11.sp)),
              Text('60 km', style: TextStyle(fontFamily: kFontDMSans, color: _grey, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stateDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedState.isEmpty ? null : selectedState,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _grey),
      style: TextStyle(color: _dark, fontSize: 14.sp),
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(
        hintText: 'Choose a state',
        hintStyle: TextStyle(color: _grey, fontSize: 14.sp),
        prefixIcon: const Icon(Icons.map_outlined, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _theme, width: 1.5)),
      ),
      items: states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: _dark, fontSize: 14.sp)))).toList(),
      onChanged: (v) => setState(() => selectedState = v ?? ''),
    );
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCountry.isEmpty ? null : selectedCountry,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _grey),
      style: TextStyle(color: _dark, fontSize: 14.sp),
      borderRadius: BorderRadius.circular(12),
      decoration: InputDecoration(
        hintText: 'Choose a country',
        hintStyle: TextStyle(color: _grey, fontSize: 14.sp),
        prefixIcon: const Icon(Icons.flag_outlined, color: _grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _theme, width: 1.5)),
      ),
      items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: _dark, fontSize: 14.sp)))).toList(),
      onChanged: (v) => setState(() => selectedCountry = v ?? ''),
    );
  }

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
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(color: _theme, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(skill, style: TextStyle(fontFamily: kFontDMSans, color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500)),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => setState(() => selectedSkills.remove(skill)),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
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
                child: const Icon(Icons.add_circle_outline, color: _theme, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addSkill(String val) {
    val = val.trim();
    if (val.isEmpty) return;
    // Normalize to title case so "react" and "React" are treated as the same skill
    final normalized = val[0].toUpperCase() + val.substring(1).toLowerCase();
    final alreadyAdded = selectedSkills.any(
      (s) => s.toLowerCase() == normalized.toLowerCase(),
    );
    if (!alreadyAdded) {
      setState(() {
        selectedSkills.add(normalized);
        _skillInputController.clear();
      });
    }
  }

  Widget _postedWithinChips() {
    const entries = [
      ('24h', 'Past 24h'),
      ('7d', 'Past Week'),
      ('30d', '1 Month'),
      ('90d', '3 Months'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        final isSelected = postedWithin == entry.$1;
        return GestureDetector(
          onTap: () => setState(() => postedWithin = isSelected ? '' : entry.$1),
          child: _chip(entry.$2, isSelected),
        );
      }).toList(),
    );
  }

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
          Text('Sort by Latest', style: TextStyle(fontFamily: kFontDMSans, color: _dark, fontSize: 14.sp, fontWeight: FontWeight.w500)),
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

  Widget _applyButtonWidget() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');

        final filterData = CreateFilterRequest(
          agentId: userId ?? '',
          selectedDomains: List<String>.from(selectedDomains),
          opportunityTypes: List<String>.from(opportunityTypes),
          selectedLocationOption: selectedLocationOption,
          selectedCity: selectedCity,
          selectedState: selectedState,
          selectedCountry: selectedCountry,
          // Distance slider only applies for City or no-location mode; zero it out otherwise
          distanceKm: (selectedLocationOption == 'City' || selectedLocationOption.isEmpty)
              ? _radiusKm.round()
              : 0,
          skills: List<String>.from(selectedSkills),
          postedWithin: postedWithin,
          sortByTime: sortByTime,
        );

        if (!mounted) return;
        final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);

        final success = await filterNotifier.createFilter(userId ?? '', filterData);

        if (!mounted) return;
        if (!success) return;

        // activeFilter is already set from the server response inside createFilter()
        Navigator.pop(context, true);
      },
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(color: _theme, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Text(
            'Apply Filters',
            style: TextStyle(fontFamily: kFontDMSans, color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}