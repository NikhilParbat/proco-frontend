import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:proco/constants/app_colors.dart';

class CountryCode {
  final String name;
  final String dialCode;
  final String flag;
  const CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

const List<CountryCode> kCountryCodes = [
  CountryCode(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  CountryCode(name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
  CountryCode(name: 'Albania', dialCode: '+355', flag: '🇦🇱'),
  CountryCode(name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
  CountryCode(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  CountryCode(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  CountryCode(name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
  CountryCode(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
  CountryCode(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  CountryCode(name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
  CountryCode(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  CountryCode(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  CountryCode(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  CountryCode(name: 'China', dialCode: '+86', flag: '🇨🇳'),
  CountryCode(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  CountryCode(name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
  CountryCode(name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
  CountryCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  CountryCode(name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹'),
  CountryCode(name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
  CountryCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  CountryCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  CountryCode(name: 'Ghana', dialCode: '+233', flag: '🇬🇭'),
  CountryCode(name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
  CountryCode(name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
  CountryCode(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  CountryCode(name: 'Iran', dialCode: '+98', flag: '🇮🇷'),
  CountryCode(name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
  CountryCode(name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
  CountryCode(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  CountryCode(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  CountryCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
  CountryCode(name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
  CountryCode(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
  CountryCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
  CountryCode(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  CountryCode(name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
  CountryCode(name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  CountryCode(name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
  CountryCode(name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
  CountryCode(name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
  CountryCode(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
  CountryCode(name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  CountryCode(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  CountryCode(name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
  CountryCode(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  CountryCode(name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  CountryCode(name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  CountryCode(name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
  CountryCode(name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  CountryCode(name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
  CountryCode(name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
  CountryCode(name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  CountryCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  CountryCode(name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  CountryCode(name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  CountryCode(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  CountryCode(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  CountryCode(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
  CountryCode(name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
  CountryCode(name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
  CountryCode(name: 'Tanzania', dialCode: '+255', flag: '🇹🇿'),
  CountryCode(name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  CountryCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  CountryCode(name: 'UAE', dialCode: '+971', flag: '🇦🇪'),
  CountryCode(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
  CountryCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  CountryCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
  CountryCode(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
];

/// Phone input field with a searchable country code prefix.
/// [darkMode] uses dark/transparent styling for onboarding screens.
/// [lightMode] (default) uses the same bordered style as profile edit fields.
class PhoneInputField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool darkMode;

  const PhoneInputField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.darkMode = false,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCode _selected;
  late final TextEditingController _numController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _selected = _parseCountry(widget.initialValue);
    _numController = TextEditingController(
      text: _stripDialCode(widget.initialValue, _selected),
    );
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _numController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  CountryCode _parseCountry(String value) {
    if (value.isEmpty) return kCountryCodes.first;
    final sorted = [...kCountryCodes]
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    for (final c in sorted) {
      if (value.startsWith(c.dialCode)) return c;
    }
    return kCountryCodes.first;
  }

  String _stripDialCode(String value, CountryCode code) {
    if (value.startsWith(code.dialCode)) {
      return value.substring(code.dialCode.length).trim();
    }
    return value;
  }

  void _emit() {
    widget.onChanged('${_selected.dialCode} ${_numController.text.trim()}');
  }

  void _openPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        selected: _selected,
        onSelect: (c) {
          setState(() => _selected = c);
          _emit();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.darkMode ? _buildDark() : _buildLight();
  }

  // ── Dark mode (onboarding) ──────────────────────────────────────────────

  Widget _buildDark() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _openPicker,
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h, right: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selected.flag} ${_selected.dialCode}',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                SizedBox(width: 2.w),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white54,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: _numController,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
            ],
            maxLength: 15,
            style: const TextStyle(color: Colors.white, fontSize: 22),
            cursorColor: kTeal,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              hintText: '00000 00000',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 22),
              counterText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: kTeal, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Light mode (profile edit) ───────────────────────────────────────────

  Widget _buildLight() {
    final focused = _focusNode.hasFocus;
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Container(
        decoration: BoxDecoration(
          color: kLight,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: focused ? kThemeColor : const Color(0xFFE0E0E0),
            width: focused ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _openPicker,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selected.flag} ${_selected.dialCode}',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14.sp,
                        color: kDark,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(Icons.arrow_drop_down, size: 18.sp, color: kDarkGrey),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 24.h, color: const Color(0xFFE0E0E0)),
            Expanded(
              child: TextField(
                controller: _numController,
                focusNode: _focusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                ],
                onChanged: (_) => _emit(),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14.sp,
                  color: kDark,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 14.h,
                  ),
                  hintText: 'Phone number',
                  hintStyle: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13.sp,
                    color: const Color(0xFFBBBBBB),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country picker bottom sheet ─────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelect;

  const _CountryPickerSheet({required this.selected, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  List<CountryCode> get _filtered {
    if (_query.isEmpty) return kCountryCodes;
    final q = _query.toLowerCase();
    return kCountryCodes
        .where(
          (c) => c.name.toLowerCase().contains(q) || c.dialCode.contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Text(
              'Select Country',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: kDark,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14.sp,
                color: kDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search country or code…',
                hintStyle: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.sp,
                  color: Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.black38,
                  size: 20.sp,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final c = _filtered[index];
                final isSelected = c.name == widget.selected.name;
                return ListTile(
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 14.sp,
                      color: kDark,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: Text(
                    c.dialCode,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13.sp,
                      color: isSelected ? kThemeColor : Colors.black45,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  tileColor: isSelected
                      ? kThemeColor.withValues(alpha: 0.06)
                      : null,
                  onTap: () => widget.onSelect(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
