import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../data/models/report_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/utils/storage_utils.dart';
import '../../providers/report_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'location_picker_widget.dart';
import '../auth/verification_screen.dart';

/// Screen for detailed case report with full patient information
class DetailedCaseReportScreen extends StatefulWidget {
  const DetailedCaseReportScreen({super.key});

  @override
  State<DetailedCaseReportScreen> createState() =>
      _DetailedCaseReportScreenState();
}

class _DetailedCaseReportScreenState extends State<DetailedCaseReportScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Basic info controllers
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  // Patient info controllers
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAddressController = TextEditingController();
  final _occupationController = TextEditingController();
  final _workplaceController = TextEditingController();
  final _healthFacilityController = TextEditingController();
  final _travelHistoryController = TextEditingController();

  // Form state
  String? _selectedDiseaseType;
  String? _selectedGender;
  DateTime? _symptomOnsetDate;
  bool _isHospitalized = false;
  bool _reporterConsent = false;
  final List<String> _selectedSymptoms = [];
  final List<String> _selectedConditions = [];
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _testResultImages = [];
  final List<XFile> _medicalCertImages = [];
  final List<_ContactPersonInput> _contactPersons = [];

  // Location state
  LatLng? _selectedCaseLocation;
  LatLng? _reporterLocation;

  List<String> _diseaseTypes = ['Dengue'];
  int _addressLookupToken = 0;

  // Common symptoms
  final List<String> _availableSymptoms = [
    'Sốt cao',
    'Đau đầu',
    'Đau cơ/khớp',
    'Mệt mỏi',
    'Phát ban',
    'Buồn nôn/Nôn',
    'Tiêu chảy',
    'Ho',
    'Khó thở',
    'Đau họng',
    'Sổ mũi',
    'Nổi mụn nước',
    'Chảy máu chân răng',
    'Xuất huyết dưới da',
    'Đau bụng',
    'Mất vị giác/khứu giác',
  ];

  // Underlying conditions
  final List<String> _availableConditions = [
    'Tiểu đường',
    'Tăng huyết áp',
    'Bệnh tim mạch',
    'Bệnh phổi mãn tính',
    'Ung thư',
    'Suy thận',
    'Bệnh gan',
    'HIV/AIDS',
    'Béo phì',
    'Thai kỳ',
    'Không có',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getReporterLocation();
      _loadDiseaseTypes();
    });
  }

  Future<void> _loadDiseaseTypes() async {
    try {
      final response = await ApiClient.instance.get(ApiConstants.diseases);
      final rows = response.data;
      if (rows is! List) return;

      final names = rows
          .map((item) => (item is Map ? item['name']?.toString().trim() : null))
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toList();

      if (names.isEmpty || !mounted) return;
      setState(() {
        _diseaseTypes = names;
        _selectedDiseaseType ??= names.first;
      });
    } catch (_) {
      // Keep fallback list if API fails
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientIdController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    _occupationController.dispose();
    _workplaceController.dispose();
    _healthFacilityController.dispose();
    _travelHistoryController.dispose();
    super.dispose();
  }

  Future<void> _getReporterLocation() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getCurrentLocation();
    if (locationProvider.currentLatLng != null) {
      setState(() {
        _reporterLocation = locationProvider.currentLatLng;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => LocationPickerDialog(
          initialLocation: _selectedCaseLocation ?? _reporterLocation,
          title: 'Chọn vị trí ca bệnh',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCaseLocation = result;
        _latController.text = result.latitude.toStringAsFixed(6);
        _lonController.text = result.longitude.toStringAsFixed(6);
      });

      // Auto-fill address from coordinates
      _fetchAndSetAddress(result.latitude, result.longitude);
    }
  }

  Future<void> _fetchAndSetAddress(double lat, double lon) async {
    final lookupToken = ++_addressLookupToken;
    try {
      final result = await GeocodingService.instance.reverseGeocode(lat, lon);
      if (mounted && lookupToken == _addressLookupToken) {
        setState(() {
          _addressController.text = result.formattedAddress;
        });
      }
    } catch (e) {
      // Silently fail - user can still enter address manually
      debugPrint('Failed to fetch address: $e');
    }
  }

  Future<void> _selectSymptomOnsetDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _symptomOnsetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày khởi phát triệu chứng',
    );

    if (date != null) {
      setState(() {
        _symptomOnsetDate = date;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<ReportProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin bắt buộc'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedDiseaseType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn loại bệnh'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final lat = double.tryParse(_latController.text);
      final lon = double.tryParse(_lonController.text);

      if (lat == null || lon == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn vị trí ca bệnh'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_reporterConsent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn cần đồng ý chia sẻ thông tin để gửi báo cáo chi tiết.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final otpConfirmed = await _confirmOtpForSubmission();
      if (!otpConfirmed) return;

      if (!mounted) return;

      final testResultImageUrls = await CloudinaryUploadService.uploadImages(
        files: _testResultImages,
        folder: 'safezone/reports/detailed/test-result',
      );
      final medicalCertImageUrls = await CloudinaryUploadService.uploadImages(
        files: _medicalCertImages,
        folder: 'safezone/reports/detailed/medical-cert',
      );

      debugPrint(
        '[DetailedReport] Uploaded testResult=${testResultImageUrls.length}, medicalCert=${medicalCertImageUrls.length}',
      );

      // Build patient info
      final patientInfo = PatientInfo(
        fullName: _patientNameController.text.trim(),
        age: int.tryParse(_patientAgeController.text),
        gender: _selectedGender,
        idNumber: _patientIdController.text.trim(),
        phone: _patientPhoneController.text.trim(),
        address: _patientAddressController.text.trim(),
        occupation: _occupationController.text.trim(),
        workplace: _workplaceController.text.trim(),
        symptomOnsetDate: _symptomOnsetDate,
        healthFacility: _healthFacilityController.text.trim(),
        isHospitalized: _isHospitalized,
        travelHistory: _travelHistoryController.text.trim(),
        contactHistory: _buildContactHistoryPayload(),
        underlyingConditions: _selectedConditions.isNotEmpty
            ? _selectedConditions
            : null,
      );

      final request = CreateReportRequest(
        diseaseType: _selectedDiseaseType!,
        description: _descriptionController.text.trim(),
        lat: lat,
        lon: lon,
        reporterLat: _reporterLocation?.latitude,
        reporterLon: _reporterLocation?.longitude,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        symptoms: _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
        affectedCount: 1,
        isDetailedReport: true,
        reporterConsent: _reporterConsent,
        deviceId: await StorageUtils.getOrCreateDeviceId(),
        hasTestResult: testResultImageUrls.isNotEmpty,
        testResultImageUrls:
          testResultImageUrls.isNotEmpty ? testResultImageUrls : null,
        medicalCertImageUrls:
          medicalCertImageUrls.isNotEmpty ? medicalCertImageUrls : null,
        patientInfo: patientInfo,
      );

      final success = await provider.createReport(request);

      if (mounted) {
        if (success) {
          notificationProvider.loadNotifications();
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Gửi báo cáo thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _confirmOtpForSubmission() async {
    final authProvider = context.read<AuthProvider>();
    if (!mounted) return false;

    final selectedType = await _pickOtpChannel(authProvider);
    if (selectedType == null) {
      return false;
    }

    if (!mounted) return false;

    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(type: selectedType, canSkip: false),
      ),
    );

    if (verified != true && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Xác thực OTP thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<VerificationType?> _pickOtpChannel(AuthProvider authProvider) async {
    final email = authProvider.user?.email?.trim() ?? '';
    final phone = authProvider.user?.phone.trim() ?? '';

    final canUseEmail = email.isNotEmpty;
    final canUsePhone = phone.isNotEmpty;

    if (!canUseEmail && !canUsePhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bạn cần xác minh email hoặc số điện thoại trước khi gửi báo cáo.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return showDialog<VerificationType>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chọn phương thức xác minh'),
          content: const Text(
            'Vui lòng chọn kênh nhận OTP để xác minh trước khi gửi báo cáo.',
          ),
          actions: [
            if (canUseEmail)
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(VerificationType.email),
                icon: const Icon(Icons.email_outlined),
                label: const Text('OTP qua Email'),
              ),
            if (canUsePhone)
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(VerificationType.phone),
                icon: const Icon(Icons.phone_android),
                label: const Text('OTP qua SĐT'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  String? _buildContactHistoryPayload() {
    if (_contactPersons.isEmpty) return null;
    final contacts = _contactPersons
        .where((c) => c.name.trim().isNotEmpty)
        .map(
          (c) => {
            'name': c.name.trim(),
            if (c.phone.trim().isNotEmpty) 'phone': c.phone.trim(),
            if (c.relationship.trim().isNotEmpty)
              'relationship': c.relationship.trim(),
            if (c.address.trim().isNotEmpty) 'address': c.address.trim(),
          },
        )
        .toList();
    if (contacts.isEmpty) return null;
    return jsonEncode(contacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo chi tiết ca bệnh'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _submitReport();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isBusy = provider.isLoading || _isSubmitting;
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy ? null : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _currentStep == 3 ? 'Gửi báo cáo' : 'Tiếp tục',
                              ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: isBusy ? null : details.onStepCancel,
                              child: const Text('Quay lại'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Thông tin cơ bản'),
                      subtitle: const Text('Loại bệnh và mô tả'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildBasicInfoStep(),
                    ),
                    Step(
                      title: const Text('Thông tin bệnh nhân'),
                      subtitle: const Text('Họ tên, tuổi, địa chỉ...'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildPatientInfoStep(),
                    ),
                    Step(
                      title: const Text('Lịch sử y tế'),
                      subtitle: const Text('Triệu chứng, bệnh nền...'),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildMedicalHistoryStep(),
                    ),
                    Step(
                      title: const Text('Vị trí & Xác nhận'),
                      subtitle: const Text('Vị trí ca bệnh'),
                      isActive: _currentStep >= 3,
                      state: StepState.indexed,
                      content: _buildLocationStep(),
                    ),
                  ],
                ),
              ),
              if (provider.isLoading || _isSubmitting)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Disease type
        DropdownButtonFormField<String>(
          initialValue: _selectedDiseaseType,
          decoration: InputDecoration(
            labelText: 'Loại bệnh *',
            prefixIcon: const Icon(Icons.coronavirus),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _diseaseTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _selectedDiseaseType = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn loại bệnh';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Mô tả tình trạng *',
            hintText: 'Mô tả chi tiết về ca bệnh...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mô tả';
            }
            if (value.trim().length < 10) {
              return 'Mô tả phải có ít nhất 10 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.green.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Số ca được tự động đặt là 1 cho mỗi báo cáo chi tiết ca bệnh.',
                    style: TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông tin bệnh nhân sẽ được bảo mật và chỉ dùng cho mục đích y tế',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Patient name
        TextFormField(
          controller: _patientNameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên bệnh nhân',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Age and Gender row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _patientAgeController,
                decoration: InputDecoration(
                  labelText: 'Tuổi',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ID Number
        TextFormField(
          controller: _patientIdController,
          decoration: InputDecoration(
            labelText: 'CCCD/CMND',
            prefixIcon: const Icon(Icons.badge),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Phone
        TextFormField(
          controller: _patientPhoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Address
        TextFormField(
          controller: _patientAddressController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ thường trú',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Occupation & Workplace
        TextFormField(
          controller: _occupationController,
          decoration: InputDecoration(
            labelText: 'Nghề nghiệp',
            prefixIcon: const Icon(Icons.work),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _workplaceController,
          decoration: InputDecoration(
            labelText: 'Nơi làm việc/học tập',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalHistoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Symptom onset date
        InkWell(
          onTap: _selectSymptomOnsetDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Ngày khởi phát triệu chứng',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _symptomOnsetDate != null
                  ? DateFormat('dd/MM/yyyy').format(_symptomOnsetDate!)
                  : 'Chọn ngày',
              style: TextStyle(
                color: _symptomOnsetDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Symptoms selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Triệu chứng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSymptoms.map((symptom) {
                    final isSelected = _selectedSymptoms.contains(symptom);
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Underlying conditions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bệnh nền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableConditions.map((condition) {
                    final isSelected = _selectedConditions.contains(condition);
                    return FilterChip(
                      label: Text(condition),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildEvidenceImageSection(
          title: 'Ảnh kết quả xét nghiệm',
          subtitle: 'Có thể bỏ trống nếu chưa có kết quả xét nghiệm.',
          images: _testResultImages,
          onPickGallery: () => _pickEvidenceImage(
            target: _testResultImages,
            source: ImageSource.gallery,
          ),
          onPickCamera: () => _pickEvidenceImage(
            target: _testResultImages,
            source: ImageSource.camera,
          ),
          onRemove: (index) => _removeEvidenceImage(_testResultImages, index),
        ),
        const SizedBox(height: 16),

        _buildEvidenceImageSection(
          title: 'Ảnh giấy tờ y tế',
          subtitle: 'Ví dụ: giấy khám, phiếu chỉ định, đơn thuốc.',
          images: _medicalCertImages,
          onPickGallery: () => _pickEvidenceImage(
            target: _medicalCertImages,
            source: ImageSource.gallery,
          ),
          onPickCamera: () => _pickEvidenceImage(
            target: _medicalCertImages,
            source: ImageSource.camera,
          ),
          onRemove: (index) => _removeEvidenceImage(_medicalCertImages, index),
        ),
        const SizedBox(height: 16),

        // Health facility
        TextFormField(
          controller: _healthFacilityController,
          decoration: InputDecoration(
            labelText: 'Cơ sở y tế điều trị (nếu có)',
            prefixIcon: const Icon(Icons.local_hospital),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Hospitalized checkbox
        CheckboxListTile(
          title: const Text('Đang nhập viện điều trị'),
          value: _isHospitalized,
          onChanged: (value) {
            setState(() => _isHospitalized = value ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Travel history
        TextFormField(
          controller: _travelHistoryController,
          decoration: InputDecoration(
            labelText: 'Lịch sử di chuyển (14 ngày qua)',
            hintText: 'Các địa điểm đã đi...',
            prefixIcon: const Icon(Icons.flight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Contact persons (structured)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Người tiếp xúc gần',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _contactPersons.add(_ContactPersonInput());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm người'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_contactPersons.isEmpty)
                  Text(
                    'Chưa có người tiếp xúc nào được khai báo.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ..._contactPersons.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final person = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Người ${idx + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _contactPersons.removeAt(idx);
                                });
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              tooltip: 'Xóa người này',
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: person.name,
                          decoration: const InputDecoration(
                            labelText: 'Họ tên *',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => person.name = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: person.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => person.phone = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: person.relationship,
                          decoration: const InputDecoration(
                            labelText: 'Mối quan hệ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => person.relationship = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: person.address,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ liên hệ',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => person.address = v,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Address
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ xảy ra ca bệnh',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Map picker button
        ElevatedButton.icon(
          onPressed: _openMapPicker,
          icon: const Icon(Icons.map),
          label: Text(
            _selectedCaseLocation != null
                ? 'Đã chọn vị trí (${_latController.text}, ${_lonController.text})'
                : 'Chọn vị trí trên bản đồ *',
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: _selectedCaseLocation != null
                ? Colors.green
                : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Confirmation note
        Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Xác nhận thông tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Báo cáo chi tiết ca bệnh sẽ được gửi đến cơ quan y tế để xác minh. '
                  'Vui lòng đảm bảo thông tin chính xác. '
                  'Cơ quan y tế có thể liên hệ để xác minh thêm nếu cần.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _reporterConsent,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      _reporterConsent = value ?? false;
                    });
                  },
                  title: const Text(
                    'Tôi đồng ý chia sẻ thông tin này với cơ quan y tế để phục vụ giám sát dịch bệnh.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickEvidenceImage({
    required List<XFile> target,
    required ImageSource source,
  }) async {
    if (target.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mỗi nhóm chỉ tối đa 4 ảnh')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 95,
    );
    if (picked == null) return;

    setState(() {
      target.add(picked);
    });
  }

  void _removeEvidenceImage(List<XFile> target, int index) {
    setState(() {
      target.removeAt(index);
    });
  }

  Widget _buildEvidenceImageSection({
    required String title,
    required String subtitle,
    required List<XFile> images,
    required VoidCallback onPickGallery,
    required VoidCallback onPickCamera,
    required void Function(int index) onRemove,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${images.length}/4',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hỗ trợ: jpg, jpeg, png, webp, heic, heif. Tối đa 5MB/ảnh.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...images.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                image.path,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(image.path),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Thư viện'),
                ),
                OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPersonInput {
  String name = '';
  String phone = '';
  String relationship = '';
  String address = '';
}
