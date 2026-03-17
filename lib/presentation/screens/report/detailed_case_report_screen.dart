import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../data/models/report_model.dart';
import '../../../core/services/geocoding_service.dart';
import '../../providers/report_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'location_picker_widget.dart';
import 'verification_required_dialog.dart';
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

  // Basic info controllers
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _affectedCountController = TextEditingController(text: '1');
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
  final _contactHistoryController = TextEditingController();

  // Form state
  String? _selectedDiseaseType;
  String? _selectedGender;
  DateTime? _symptomOnsetDate;
  bool _isHospitalized = false;
  final List<String> _selectedSymptoms = [];
  final List<String> _selectedConditions = [];

  // Location state
  LatLng? _selectedCaseLocation;
  LatLng? _reporterLocation;

  // Disease types
  final List<String> _diseaseTypes = [
    'Sốt xuất huyết',
    'Tay chân miệng',
    'COVID-19',
    'Cúm mùa',
    'Sởi',
    'Thủy đậu',
    'Tiêu chảy cấp',
    'Tả',
    'Viêm gan',
    'Lao',
    'HIV/AIDS',
    'Khác',
  ];

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
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _affectedCountController.dispose();
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
    _contactHistoryController.dispose();
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
    try {
      final result = await GeocodingService.instance.reverseGeocode(lat, lon);
      if (mounted && _addressController.text.isEmpty) {
        setState(() {
          _addressController.text = result.formattedAddress;
        });
      }
    } catch (e) {
      // Silently fail - user can still enter address manually
      print('Failed to fetch address: $e');
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

    // Check verification status
    final isVerified = await VerificationRequiredDialog.show(context);
    if (!isVerified) return;

    final authProvider = context.read<AuthProvider>();
    final hasEmail = authProvider.user?.email?.isNotEmpty == true;
    if (!hasEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cập nhật email trước khi gửi báo cáo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final otpConfirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const VerificationScreen(
          type: VerificationType.email,
          canSkip: false,
        ),
      ),
    );
    if (otpConfirmed != true) return;

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
      contactHistory: _contactHistoryController.text.trim(),
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
      affectedCount: int.tryParse(_affectedCountController.text),
      isDetailedReport: true,
      patientInfo: patientInfo,
    );

    final provider = context.read<ReportProvider>();
    final success = await provider.createReport(request);

    if (mounted) {
      if (success) {
        context.read<NotificationProvider>().loadNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo chi tiết đã được gửi thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: details.onStepContinue,
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
                              onPressed: details.onStepCancel,
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
              if (provider.isLoading)
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
          value: _selectedDiseaseType,
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
            if (value == null || value.isEmpty)
              return 'Vui lòng chọn loại bệnh';
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

        // Affected count
        TextFormField(
          controller: _affectedCountController,
          decoration: InputDecoration(
            labelText: 'Số người bị ảnh hưởng',
            prefixIcon: const Icon(Icons.people),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
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
                value: _selectedGender,
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

        // Contact history
        TextFormField(
          controller: _contactHistoryController,
          decoration: InputDecoration(
            labelText: 'Lịch sử tiếp xúc',
            hintText: 'Những người đã tiếp xúc gần...',
            prefixIcon: const Icon(Icons.group),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 32),
                SizedBox(height: 8),
                Text(
                  'Xác nhận thông tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Báo cáo chi tiết ca bệnh sẽ được gửi đến cơ quan y tế để xác minh. '
                  'Vui lòng đảm bảo thông tin chính xác. '
                  'Cơ quan y tế có thể liên hệ để xác minh thêm nếu cần.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
