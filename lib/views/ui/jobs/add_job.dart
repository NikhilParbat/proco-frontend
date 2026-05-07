import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proco/constants/app_constants.dart';
import 'package:proco/controllers/exports.dart';
import 'package:proco/models/request/jobs/create_job.dart';
import 'package:proco/models/response/jobs/jobs_response.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:proco/views/ui/auth/location_picker_screen.dart';
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
  static const Color _sectionColor = Color(0xFF888888);

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _periodController = TextEditingController();
  final _contractController = TextEditingController();
  final _customDomainController = TextEditingController();
  final _skillInputController = TextEditingController();
  final List<TextEditingController> _reqControllers = [];

  // ─── State ────────────────────────────────────────────────────────────────
  double _jobLat = 0.0;
  double _jobLng = 0.0;
  bool _locationPicked = false;
  bool _isHiring = true;
  String? selectedDomain;
  String? selectedOpportunityType;
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
      _salaryController.text = j.salary;
      _periodController.text = j.period;
      _contractController.text = j.contract;
      _isHiring = j.hiring;
      _jobLat = j.latitude;
      _jobLng = j.longitude;
      _locationPicked = true;
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

      if (kDomains.contains(j.domain)) {
        selectedDomain = j.domain;
      } else if (j.domain.isNotEmpty) {
        selectedDomain = 'Other';
        _customDomainController.text = j.domain;
      }

      if (kOpportunityTypes.contains(j.opportunityType)) {
        selectedOpportunityType = j.opportunityType;
      }
    } else {
      _reqControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _periodController.dispose();
    _contractController.dispose();
    _customDomainController.dispose();
    _skillInputController.dispose();
    for (final c in _reqControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Requirements ─────────────────────────────────────────────────────────
  void _addRequirement() =>
      setState(() => _reqControllers.add(TextEditingController()));

  void _removeRequirement(int index) => setState(() {
    _reqControllers[index].dispose();
    _reqControllers.removeAt(index);
    if (_reqControllers.isEmpty) _reqControllers.add(TextEditingController());
  });

  // ─── Skills ───────────────────────────────────────────────────────────────
  void _addSkill(String skill) {
    final s = skill.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() {
        _skills.add(s);
        _skillInputController.clear();
      });
    }
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
        setState(() =>
            _locationController.text = '${address.city}, ${address.state}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationController.text = widget.job!.location);
      }
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submit(
    JobsNotifier notifier,
    ImageNotifier imageNotifier,
  ) async {
    if (selectedDomain == null || selectedOpportunityType == null) {
      _snack('Please select a domain and opportunity type.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _snack('Please enter an opportunity title.');
      return;
    }

    final effectiveDomain = selectedDomain == 'Other'
        ? _customDomainController.text.trim()
        : selectedDomain!;

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

    final jobData = CreateJobsRequest(
      agentId: userId,
      domain: effectiveDomain,
      opportunityType: selectedOpportunityType!,
      title: _titleController.text.trim(),
      city: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'Remote',
      latitude: _jobLat,
      longitude: _jobLng,
      company: _companyController.text.trim(),
      description: _descriptionController.text.trim(),
      salary: _salaryController.text.trim(),
      period: _periodController.text.trim(),
      hiring: _isHiring,
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
        Navigator.pop(context);
      }
    } else {
      await notifier.createJob(
        jobData,
        context,
        imageFile: imageNotifier.selectedImage,
      );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: _textDark, size: 22),
        ),
        title: Text(
          _isEditMode ? 'Edit Query' : 'Create Query',
          style: const TextStyle(
            fontFamily: kFontDMSans,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ),
      body: Consumer2<JobsNotifier, ImageNotifier>(
        builder: (context, jobsNotifier, imageNotifier, _) {
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            children: [
              // ── BASIC INFO ────────────────────────────────────────────────
              _sectionLabel('BASIC INFO'),
              SizedBox(height: 10.h),
              _field(_titleController, hint: 'Query title *',
                  inputFormatters: [noEmojiFormatter], maxLength: 50),
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
                _isHiring,
                (v) => setState(() => _isHiring = v),
              ),
              SizedBox(height: 24.h),

              // ── CATEGORY ──────────────────────────────────────────────────
              _sectionLabel('CATEGORY'),
              SizedBox(height: 10.h),
              Text('Domain', style: _labelStyle()),
              SizedBox(height: 8.h),
              _domainChips(),
              if (selectedDomain == 'Other') ...[
                SizedBox(height: 8.h),
                _field(
                  _customDomainController,
                  hint: 'Type your domain...',
                ),
              ],
              SizedBox(height: 14.h),
              Text('Opportunity Type', style: _labelStyle()),
              SizedBox(height: 8.h),
              _opportunityTypeChips(),
              SizedBox(height: 24.h),

              // ── COMPENSATION ──────────────────────────────────────────────
              _sectionLabel('COMPENSATION'),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _salaryController,
                      hint: 'Salary / Reward',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _field(_periodController, hint: 'Period'),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
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
                  height: 140.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: imageNotifier.selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imageNotifier.selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: _textGrey,
                              size: 32,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'Tap to add image',
                              style: TextStyle(
                                fontFamily: kFontDMSans,
                                fontSize: 13.sp,
                                color: _textGrey,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (imageNotifier.selectedImage != null) ...[
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () => imageNotifier.clearImage(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close, color: Colors.redAccent, size: 14),
                      SizedBox(width: 4.w),
                      Text(
                        'Remove image',
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 12.sp,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 32.h),

              // ── Submit ────────────────────────────────────────────────────
              GestureDetector(
                onTap: () => _submit(jobsNotifier, imageNotifier),
                child: Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: kThemeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _isEditMode ? 'Update Query' : 'Create Query',
                      style: TextStyle(
                        fontFamily: kFontDMSans,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          );
        },
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: kFontDMSans,
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: _sectionColor,
        letterSpacing: 1.2,
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
        fontSize: 14.sp,
        color: _textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: kFontDMSans,
          fontSize: 14.sp,
          color: _textGrey,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kThemeColor, width: 1.5),
        ),
      ),
    );
  }

  // ─── Location picker row ──────────────────────────────────────────────────
  Widget _locationPicker() {
    return GestureDetector(
      onTap: () async {
        final LatLng? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerScreen(
              initialPosition: LatLng(_jobLat, _jobLng),
            ),
          ),
        );
        if (result != null) {
          final address = await LocationService.getAddressFromLatLng(
            result.latitude,
            result.longitude,
          );
          setState(() {
            _jobLat = result.latitude;
            _jobLng = result.longitude;
            _locationPicked = true;
            _locationController.text =
                '${address.city}, ${address.state}';
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _locationPicked ? kThemeColor : _border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: _locationPicked ? kThemeColor : _textGrey,
              size: 18,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _locationPicked
                    ? _locationController.text
                    : 'Pin opportunity location on map',
                style: TextStyle(
                  fontFamily: kFontDMSans,
                  fontSize: 14.sp,
                  color: _locationPicked ? _textDark : _textGrey,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Toggle row ───────────────────────────────────────────────────────────
  Widget _toggleRow(
      String label, bool value, ValueChanged<bool> onChanged) {
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

  // ─── Domain chips (kDomains + Other) ─────────────────────────────────────
  Widget _domainChips() {
    final domains = [...kDomains, 'Other'];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: domains.map((d) {
        final selected = selectedDomain == d;
        return GestureDetector(
          onTap: () => setState(() => selectedDomain = d),
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? kThemeColor : const Color(0xFFDDDDDD),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              d,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: selected ? kThemeColor : const Color(0xFF444444),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Opportunity type chips ───────────────────────────────────────────────
  Widget _opportunityTypeChips() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: kOpportunityTypes.map((type) {
        final selected = selectedOpportunityType == type;
        return GestureDetector(
          onTap: () => setState(() => selectedOpportunityType = type),
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? kThemeColor : const Color(0xFFDDDDDD),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontFamily: kFontDMSans,
                fontSize: 13.sp,
                color: selected ? kThemeColor : const Color(0xFF444444),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
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
                      horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kDarkBlue,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.value,
                        style: TextStyle(
                          fontFamily: kFontDMSans,
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => _removeSkill(e.key),
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 14),
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
                  style: TextStyle(
                    fontFamily: kFontDMSans,
                    fontSize: 14.sp,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: _skills.isEmpty
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
              GestureDetector(
                onTap: () => _addSkill(_skillInputController.text),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: kThemeColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: kFontDMSans,
                      fontSize: 12.sp,
                      color: Colors.white,
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
