import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proco/services/location_service.dart';

class AddJobPage extends StatefulWidget {
  final JobsResponse? job;
  const AddJobPage({super.key, this.job});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  // ─── Design tokens ────────────────────────────────────────────────────────
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textGrey = Color(0xFF999999);

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _durationValueController = TextEditingController();
  final _contractController = TextEditingController();
  final _customDomainController = TextEditingController();
  final _skillInputController = TextEditingController();
  final List<TextEditingController> _reqControllers = [];

  // ─── Location state ────────────────────────────────────────────────────────
  final _locationSearchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _locationResults = [];
  bool _isSearchingLocation = false;
  bool _isFetchingCurrentLocation = false;
  String? _selectedLocationLabel;
  bool _preferTypingLocation = false;

  // ─── Other state ──────────────────────────────────────────────────────────
  double _jobLat = 0.0;
  double _jobLng = 0.0;
  bool _isActive = true;
  String _currency = '₹';
  String _durationUnit = 'Months';
  List<String> selectedDomains = [];
  String? _selectedOpportunityType;
  List<String> _skills = [];

  bool get _isEditMode => widget.job != null;
  late final ImageNotifier _imageNotifier;

  @override
  void initState() {
    super.initState();
    _imageNotifier = ImageNotifier();

    final j = widget.job;
    if (j != null) {
      _titleController.text = j.title;
      _companyController.text = j.company;
      _descriptionController.text = j.description;

      final rawSalary = j.salary;
      if (rawSalary.startsWith('\$')) {
        _currency = '\$';
        _salaryController.text = rawSalary.substring(1);
      } else if (rawSalary.startsWith('₹')) {
        _currency = '₹';
        _salaryController.text = rawSalary.substring(1);
      } else {
        _salaryController.text = rawSalary;
      }

      final parts = j.period.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && ['Days', 'Months', 'Years'].contains(parts[1])) {
        _durationValueController.text = parts[0];
        _durationUnit = parts[1];
      } else {
        _durationValueController.text = j.period;
      }
      _contractController.text = j.contract;
      _isActive = j.isActive;
      _jobLat = j.latitude;
      _jobLng = j.longitude;
      _reverseGeocodeExistingLocation();

      _reqControllers.clear();
      if (j.requirements.isNotEmpty) {
        for (final r in j.requirements) {
          _reqControllers.add(TextEditingController(text: r));
        }
      } else {
        _reqControllers.add(TextEditingController());
      }

      _skills = List.from(j.skills);

      if (j.domain.isNotEmpty) {
        final splitDomains = j.domain.split(',').map((e) => e.trim()).toList();
        for (final d in splitDomains) {
          if (kDomains.contains(d)) selectedDomains.add(d);
        }
        final customDomains = splitDomains.where((d) => !kDomains.contains(d));
        if (customDomains.isNotEmpty) {
          selectedDomains.add('Other');
          _customDomainController.text = customDomains.join(', ');
        }
      }

      if (kOpportunityTypes.contains(j.opportunityType)) {
        _selectedOpportunityType = j.opportunityType;
      }
    } else {
      _reqControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationSearchCtrl.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _durationValueController.dispose();
    _contractController.dispose();
    _customDomainController.dispose();
    _skillInputController.dispose();
    for (final c in _reqControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Requirements ─────────────────────────────────────────────────────────
  void _addRequirement() {
    if (_reqControllers.isNotEmpty &&
        _reqControllers.last.text.trim().isEmpty) {
      _snack('Please fill in the current requirement before adding another.');
      return;
    }
    setState(() => _reqControllers.add(TextEditingController()));
  }

  void _removeRequirement(int index) => setState(() {
    _reqControllers[index].dispose();
    _reqControllers.removeAt(index);
    if (_reqControllers.isEmpty) _reqControllers.add(TextEditingController());
  });

  // ─── Skills ───────────────────────────────────────────────────────────────
  void _addSkill(String skill) {
    final s = skill.trim();
    if (s.isEmpty || _skills.contains(s)) return;
    if (_skills.length >= 9) {
      _snack('Maximum 9 skills allowed.');
      return;
    }
    setState(() {
      _skills.add(s);
      _skillInputController.clear();
    });
  }

  void _removeSkill(int i) => setState(() => _skills.removeAt(i));

  // ─── Location ─────────────────────────────────────────────────────────────
  Future<void> _reverseGeocodeExistingLocation() async {
    try {
      final address = await LocationService.getAddressFromLatLng(
        _jobLat,
        _jobLng,
      );
      if (mounted) {
        final label = '${address.city}, ${address.state}';
        setState(() {
          _selectedLocationLabel = label;
          _locationSearchCtrl.text = label;
        });
      }
    } catch (_) {
      if (mounted) {
        final fallback = widget.job!.location;
        setState(() {
          _selectedLocationLabel = fallback;
          _locationSearchCtrl.text = fallback;
        });
      }
    }
  }

  Future<void> _onLocationSearchChanged(String query) async {
    if (query.trim().length < 3) {
      if (mounted) {
        setState(() {
          _locationResults.clear();
          _isSearchingLocation = false;
        });
      }
      return;
    }
    setState(() => _isSearchingLocation = true);
    try {
      final url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'proco_app'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _locationResults
            ..clear()
            ..addAll(
              data.map((item) {
                final addr = item['address'] as Map<String, dynamic>? ?? {};
                return {
                  'display_name': item['display_name'],
                  'lat': double.parse(item['lat']),
                  'lon': double.parse(item['lon']),
                  'city':
                      addr['city'] ??
                      addr['town'] ??
                      addr['village'] ??
                      addr['county'] ??
                      '',
                  'state': addr['state'] ?? '',
                  'country': addr['country'] ?? '',
                };
              }),
            );
        });
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    } finally {
      if (mounted) setState(() => _isSearchingLocation = false);
    }
  }

  void _selectLocationResult(Map<String, dynamic> item) {
    final lat = item['lat'] as double;
    final lon = item['lon'] as double;
    final display = (item['display_name'] as String?) ?? '';
    setState(() {
      _jobLat = lat;
      _jobLng = lon;
      _selectedLocationLabel = display;
      _locationSearchCtrl.text = display;
      _locationResults.clear();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingCurrentLocation = true);
    try {
      final result = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromLatLng(
        result.latitude,
        result.longitude,
      );
      if (!mounted) return;
      final display = result.displayAddress?.isNotEmpty == true
          ? result.displayAddress!
          : '${address.city}, ${address.state}';
      setState(() {
        _jobLat = result.latitude;
        _jobLng = result.longitude;
        _selectedLocationLabel = display;
        _locationSearchCtrl.text = display;
      });
    } catch (e) {
      if (mounted) _snack('Could not fetch location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingCurrentLocation = false);
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit(
    JobsNotifier notifier,
    ImageNotifier imageNotifier,
  ) async {
    if (selectedDomains.isEmpty || _selectedOpportunityType == null) {
      _snack('Please select a domain and opportunity type.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter an opportunity title.');
      return;
    }

    final domains = [...selectedDomains];
    if (domains.contains('Other')) {
      domains.remove('Other');
      if (_customDomainController.text.trim().isNotEmpty) {
        domains.add(_customDomainController.text.trim());
      }
    }
    final effectiveDomain = domains.join(', ');
    if (effectiveDomain.isEmpty) {
      _snack('Please enter a custom domain.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) {
      if (!mounted) return;
      _snack('You must be logged in to list an opportunity.');
      return;
    }

    final requirements = _reqControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cityLabel = _selectedLocationLabel?.trim() ?? '';

    final jobData = CreateJobsRequest(
      agentId: userId,
      domain: effectiveDomain,
      opportunityType: _selectedOpportunityType ?? '',
      title: _titleController.text.trim(),
      city: cityLabel.isNotEmpty ? cityLabel : 'Remote',
      latitude: _jobLat,
      longitude: _jobLng,
      company: _companyController.text.trim(),
      description: _descriptionController.text.trim(),
      salary: _salaryController.text.trim().isEmpty
          ? ''
          : '$_currency${_salaryController.text.trim()}',
      period: _durationValueController.text.trim().isEmpty
          ? ''
          : '${_durationValueController.text.trim()} $_durationUnit',
      isActive: _isActive,
      contract: _contractController.text.trim(),
      requirements: requirements,
      skills: _skills,
      imageUrl: _isEditMode ? (widget.job?.imageUrl ?? '') : '',
    );

    if (!mounted) return;

    if (_isEditMode) {
      await notifier.updateJob(
        widget.job!.id,
        jobData,
        context,
        imageFile: imageNotifier.selectedImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opportunity updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } else {
      await notifier.createJob(
        jobData,
        context,
        imageFile: imageNotifier.selectedImage,
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _imageNotifier,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,

      bottomNavigationBar: Consumer2<JobsNotifier, ImageNotifier>(
        builder: (context, jobsNotifier, imageNotifier, _) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: GestureDetector(
                onTap: () => _submit(jobsNotifier, imageNotifier),
                child: Container(
                  height: 58.h,
                  decoration: BoxDecoration(
                    color: kThemeColor,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: kThemeColor.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isEditMode
                            ? 'Update Opportunity'
                            : 'Create Opportunity',
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kDark,
              size: 20.sp,
            ),
          ),
        ),
        title: Text(
          _isEditMode ? 'Edit Opportunity' : 'Post Opportunity',
          style: TextStyle(
            fontFamily: kFontDMSans,
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
            color: kDark,
          ),
        ),
      ),

      body: Consumer2<JobsNotifier, ImageNotifier>(
        builder: (context, jobsNotifier, imageNotifier, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 120.h),
            children: [
              // ── BASIC INFO ────────────────────────────────────────────────
              _sectionLabel('BASIC INFO'),
              SizedBox(height: 10.h),
              _field(
                _titleController,
                hint: 'Opportunity title',
                inputFormatters: [noEmojiFormatter],
                maxLength: 50,
              ),
              SizedBox(height: 10.h),
              _field(_companyController, hint: 'Company name (optional)'),
              SizedBox(height: 24.h),

              // ── LOCATION ──────────────────────────────────────────────────
              _sectionLabel('LOCATION'),
              SizedBox(height: 10.h),
              _locationPicker(),
              SizedBox(height: 10.h),
              _toggleRow(
                'Actively Accepting Responses',
                _isActive,
                (v) => setState(() => _isActive = v),
              ),
              SizedBox(height: 24.h),

              // ── CATEGORY ──────────────────────────────────────────────────
              _sectionLabel('CATEGORY'),
              SizedBox(height: 10.h),
              Text('Domain', style: _labelStyle()),
              SizedBox(height: 8.h),
              _domainChips(),
              if (selectedDomains.contains('Other')) ...[
                SizedBox(height: 8.h),
                _field(_customDomainController, hint: 'Type your domain...'),
              ],
              SizedBox(height: 14.h),
              Text('Opportunity Type', style: _labelStyle()),
              SizedBox(height: 8.h),
              _opportunityTypeSelector(),
              SizedBox(height: 24.h),

              // ── COMPENSATION ──────────────────────────────────────────────
              _sectionLabel('COMPENSATION'),
              SizedBox(height: 10.h),
              Text('Stipend', style: _labelStyle()),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Container(
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFD2D6DE)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        items: const [
                          DropdownMenuItem(value: '₹', child: Text('₹  INR')),
                          DropdownMenuItem(value: '\$', child: Text('\$  USD')),
                        ],
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 15.sp,
                          color: const Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w600,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18.sp,
                          color: const Color(0xFF9EA4B0),
                        ),
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _field(
                      _salaryController,
                      hint: 'Amount',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text('Duration', style: _labelStyle()),
              SizedBox(height: 8.h),
              Row(
                children: [
                  SizedBox(
                    width: 90.w,
                    child: _field(
                      _durationValueController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFD2D6DE)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _durationUnit,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          style: TextStyle(
                            fontFamily: kFontDMSans,
                            fontSize: 15.sp,
                            color: const Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w500,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18.sp,
                            color: const Color(0xFF9EA4B0),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Days',
                              child: Text('Days'),
                            ),
                            DropdownMenuItem(
                              value: 'Months',
                              child: Text('Months'),
                            ),
                            DropdownMenuItem(
                              value: 'Years',
                              child: Text('Years'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _durationUnit = v!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _field(_contractController, hint: 'Contract type'),
              SizedBox(height: 24.h),

              // ── DESCRIPTION ───────────────────────────────────────────────
              _sectionLabel('DESCRIPTION'),
              SizedBox(height: 10.h),
              _field(
                _descriptionController,
                hint: 'Describe the role...',
                maxLines: 4,
                maxLength: 700,
                inputFormatters: [noEmojiFormatter],
              ),
              SizedBox(height: 24.h),

              // ── REQUIREMENTS ──────────────────────────────────────────────
              _sectionLabel('REQUIREMENTS'),
              SizedBox(height: 10.h),
              ..._reqControllers.asMap().entries.map((entry) {
                final i = entry.key;
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: _field(
                          entry.value,
                          hint: 'Requirement ${i + 1}',
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () => _removeRequirement(i),
                        child: Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: _addRequirement,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: kThemeColor, size: 18),
                      SizedBox(width: 6.w),
                      Text(
                        'Add Requirement',
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 13.sp,
                          color: kThemeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // ── TECHNICAL & SKILLS ────────────────────────────────────────
              _sectionLabel('TECHNICAL & SKILLS'),
              SizedBox(height: 10.h),
              Text('Skills', style: _labelStyle()),
              SizedBox(height: 8.h),
              _skillsInput(),
              SizedBox(height: 24.h),

              // ── MEDIA ─────────────────────────────────────────────────────
              _sectionLabel('MEDIA'),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () => _showImageSourceSheet(imageNotifier),
                child: Container(
                  height: 185.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: const Color(0xFFD6D9E0),
                      width: 1.2,
                    ),
                  ),
                  child: imageNotifier.selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Image.file(
                            imageNotifier.selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54.w,
                              height: 54.w,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: kDarkGrey,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              'Upload Cover Image',
                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 15.sp,
                                color: kDarkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 22.h),
            ],
          );
        },
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: kDarkGrey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  TextStyle _labelStyle() => TextStyle(
    fontFamily: kFontDMSans,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: _textDark,
  );

  // ─── Text field ───────────────────────────────────────────────────────────
  Widget _field(
    TextEditingController controller, {
    String hint = '',
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: kFontDMSans,
        fontSize: 16.sp,
        color: kDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 16.sp,
          color: const Color(0xFF9EA4B0),
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFFD2D6DE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: kThemeColor, width: 1.4),
        ),
      ),
    );
  }

  // ─── Inline location picker ───────────────────────────────────────────────
  Widget _locationPicker() {
    final locationConfirmed = _selectedLocationLabel?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selector chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _locationChip(
              label: 'Use current location',
              icon: Icons.my_location_rounded,
              selected: !_preferTypingLocation,
              onTap: () => setState(() => _preferTypingLocation = false),
            ),
            _locationChip(
              label: 'Search location',
              icon: Icons.search,
              selected: _preferTypingLocation,
              onTap: () => setState(() => _preferTypingLocation = true),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Current-location button
        if (!_preferTypingLocation)
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton.icon(
              onPressed: _isFetchingCurrentLocation
                  ? null
                  : _useCurrentLocation,
              icon: _isFetchingCurrentLocation
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                _isFetchingCurrentLocation
                    ? 'Fetching location...'
                    : 'Fetch Current Location',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kThemeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          )
        // Search input + results
        else
          Column(
            children: [
              // Search field (reuses existing _field style)
              TextFormField(
                controller: _locationSearchCtrl,
                onChanged: _onLocationSearchChanged,
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 14.sp,
                  color: kDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search city / area',
                  hintStyle: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 14.sp,
                    color: const Color(0xFF9EA4B0),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18.sp,
                    color: const Color(0xFF9EA4B0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(
                      color: Color(0xFFD2D6DE),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: kThemeColor, width: 1.4),
                  ),
                ),
              ),
              if (_isSearchingLocation) ...[
                SizedBox(height: 6.h),
                LinearProgressIndicator(
                  minHeight: 2,
                  color: kThemeColor,
                  backgroundColor: kThemeColor.withValues(alpha: 0.15),
                ),
              ],
              if (_locationResults.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: 170.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFD2D6DE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _locationResults.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = _locationResults[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey.shade500,
                          size: 18.sp,
                        ),
                        title: Text(
                          item['display_name'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kFontDMSans,
                            fontSize: 12.sp,
                            color: _textDark,
                          ),
                        ),
                        onTap: () => _selectLocationResult(item),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

        // Confirmed location badge
        if (locationConfirmed) ...[
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: kThemeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: kThemeColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: kThemeColor, size: 16),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _selectedLocationLabel!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      color: _textDark,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Small chip used in the location mode selector
  Widget _locationChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? kThemeColor : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: selected ? kThemeColor : const Color(0xFFD2D6DE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: selected ? Colors.white : const Color(0xFF9EA4B0),
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: selected ? Colors.white : _textDark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Toggle row ───────────────────────────────────────────────────────────
  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: kFontDMSans,
              fontSize: 14.sp,
              color: _textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: kThemeColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFDDDDDD),
          ),
        ],
      ),
    );
  }

  // ─── Domain chips ─────────────────────────────────────────────────────────
  Widget _domainChips() {
    final domains = [...kDomains, 'Other'];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: domains.map((d) {
        final selected = selectedDomains.contains(d);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                selectedDomains.remove(d);
              } else if (selectedDomains.length < 3) {
                selectedDomains.add(d);
              } else {
                _snack('Maximum 3 domains allowed.');
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: selected ? kThemeColor : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: selected
                    ? kThemeColor
                    : Colors.black.withValues(alpha: 0.06),
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: kThemeColor.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              d,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: selected ? Colors.white : const Color(0xFF444444),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Opportunity type selector ────────────────────────────────────────────
  Widget _opportunityTypeSelector() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: kOpportunityTypes.map((type) {
        final isSelected = _selectedOpportunityType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedOpportunityType = type),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? kThemeColor : Colors.white,
              borderRadius: BorderRadius.circular(50.r),
              border: Border.all(
                color: isSelected ? kThemeColor : const Color(0xFFD2D6DE),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kOpportunityIcons[type] ?? Icons.work_outline,
                  size: 15.sp,
                  color: isSelected ? Colors.white : const Color(0xFF9EA4B0),
                ),
                SizedBox(width: 6.w),
                Text(
                  type,
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Skills chip input ────────────────────────────────────────────────────
  Widget _skillsInput() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD2D6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: _skills.asMap().entries.map((e) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F5),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: const Color(0xFFD5D9E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 13.sp,
                          color: kDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => _removeSkill(e.key),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8.h),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputController,
                  enabled: _skills.length < 9,
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 14.sp,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: _skills.length >= 9
                        ? 'Max 9 skills reached'
                        : _skills.isEmpty
                        ? 'Add a skill...'
                        : 'Add another skill...',
                    hintStyle: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 13.sp,
                      color: _textGrey,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _addSkill,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${_skills.length}/9',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 11.sp,
                  color: _skills.length >= 9 ? Colors.redAccent : _textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _skills.length < 9
                    ? () => _addSkill(_skillInputController.text)
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _skills.length < 9
                        ? kThemeColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 12.sp,
                      color: _skills.length < 9 ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Image source sheet ───────────────────────────────────────────────────
  void _showImageSourceSheet(ImageNotifier imageNotifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              SizedBox(height: 16.h),
              _sourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(context);
                  imageNotifier.pickImage(source: ImageSource.camera);
                },
              ),
              SizedBox(height: 10.h),
              _sourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  imageNotifier.pickImage(source: ImageSource.gallery);
                },
              ),
              SizedBox(height: 6.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: kThemeColor, size: 22),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
