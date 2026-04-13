import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
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
import '../../providers/main_tab_provider.dart';
import 'package:mobile_flutter/core/navigation/app_navigator.dart';
import 'package:mobile_flutter/presentation/screens/profile/my_reports_screen.dart';
import 'location_picker_widget.dart';
import '../auth/verification_screen.dart';
import 'detailed_case_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  // Form state
  String? _selectedDiseaseType;
  final List<String> _selectedSymptoms = [];
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedEvidenceImages = [];
  String _reportType = 'case_report'; // 'case_report' or 'outbreak_alert'
  String _severityLevel = 'medium';
  bool _isSelfReport = true;
  bool _reporterConsent = false;
  // Epidemiological
  bool? _hasContactWithPatient;
  bool? _hasVisitedEpidemicArea;
  bool? _hasSimilarCasesNearby;

  // Location state
  LatLng? _selectedCaseLocation; // Case/incident location from map
  LatLng? _reporterLocation; // Reporter's current location

  // Disease types from backend disease management
  List<String> _diseaseTypes = ['Dengue'];
  bool _isSubmitting = false;
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
  ];

  bool get _isOutbreakAlert => _reportType == 'outbreak_alert';

  Color get _themeColor =>
      _isOutbreakAlert ? Colors.orange.shade700 : Colors.red.shade600;

  String get _reportTitle =>
      _isOutbreakAlert ? 'Cảnh báo ổ dịch' : 'Báo cáo nhanh ca bệnh';

  String get _reportSubtitle => _isOutbreakAlert
      ? 'Dùng khi có nhiều ca nghi nhiễm tập trung trong khu vực.'
      : 'Dùng cho trường hợp cá nhân hoặc ca nghi nhiễm đơn lẻ.';

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Get reporter's current location when screen opens
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

  void _useCurrentLocationForCase() {
    if (_reporterLocation != null) {
      setState(() {
        _selectedCaseLocation = _reporterLocation;
        _latController.text = _reporterLocation!.latitude.toStringAsFixed(6);
        _lonController.text = _reporterLocation!.longitude.toStringAsFixed(6);
      });

      // Auto-fill address from coordinates
      _fetchAndSetAddress(
        _reporterLocation!.latitude,
        _reporterLocation!.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sử dụng vị trí hiện tại của bạn'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa lấy được vị trí của bạn. Vui lòng đợi hoặc nhập thủ công.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final reportProvider = context.read<ReportProvider>();
      final notificationProvider = context.read<NotificationProvider>();

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
            content: Text('Vui lòng nhập tọa độ hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_reporterConsent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bạn cần đồng ý chia sẻ thông tin trước khi gửi báo cáo.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final otpConfirmed = await _confirmOtpForSubmission();
      if (!otpConfirmed) {
        return;
      }

      final deviceId = await StorageUtils.getOrCreateDeviceId();
      final uploadedEvidenceUrls = await CloudinaryUploadService.uploadImages(
        files: _selectedEvidenceImages,
        folder: 'safezone/reports/quick',
      );

      debugPrint(
        '[QuickReport] Uploaded ${uploadedEvidenceUrls.length} evidence images',
      );

      final request = CreateReportRequest(
        diseaseType: _selectedDiseaseType!,
        description: _descriptionController.text.trim(),
        lat: lat,
        lon: lon,
        imageUrls: uploadedEvidenceUrls,
        reporterLat: _reporterLocation?.latitude,
        reporterLon: _reporterLocation?.longitude,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        symptoms: _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
        affectedCount: _isOutbreakAlert ? 2 : 1,
        reportType: _reportType,
        severityLevel: _severityLevel,
        isSelfReport: _isSelfReport,
        reporterConsent: _reporterConsent,
        deviceId: deviceId,
        hasContactWithPatient: _hasContactWithPatient,
        hasVisitedEpidemicArea: _hasVisitedEpidemicArea,
        hasSimilarCasesNearby: _hasSimilarCasesNearby,
      );

      final success = await reportProvider.createReport(request);

      if (mounted) {
        if (success) {
          notificationProvider.loadNotifications();
          _resetForm();

          await _showSubmitSuccessAndGoToHistory();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reportProvider.error ?? 'Gửi báo cáo thất bại'),
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

  Future<void> _showSubmitSuccessAndGoToHistory() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Gửi báo cáo thành công'),
          content: const Text(
            'Báo cáo của bạn đã được gửi. Bạn có thể theo dõi trạng thái trong Lịch sử báo cáo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Xem lịch sử báo cáo'),
            ),
          ],
        );
      },
    );

    final rootContext = AppNavigator.context;
    (rootContext ?? context).read<MainTabProvider>().setIndex(4);

    final nav = AppNavigator.state;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const MyReportsScreen()));
    } else if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyReportsScreen()),
      );
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _descriptionController.clear();
    _addressController.clear();
    _latController.clear();
    _lonController.clear();
    setState(() {
      _selectedDiseaseType = null;
      _selectedSymptoms.clear();
      _selectedEvidenceImages.clear();
      _selectedCaseLocation = null;
      _reportType = 'case_report';
      _severityLevel = 'medium';
      _isSelfReport = true;
      _reporterConsent = false;
      _hasContactWithPatient = null;
      _hasVisitedEpidemicArea = null;
      _hasSimilarCasesNearby = null;
    });
  }

  Future<void> _pickEvidenceImage(ImageSource source) async {
    if (_selectedEvidenceImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 4 ảnh minh chứng')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 95,
    );

    if (picked == null) return;

    setState(() {
      _selectedEvidenceImages.add(picked);
    });
  }

  void _removeEvidenceImage(int index) {
    setState(() {
      _selectedEvidenceImages.removeAt(index);
    });
  }

  Widget _buildYesNoQuestion(
    String question,
    bool? value,
    ValueChanged<bool?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(question, style: const TextStyle(fontSize: 13))),
          ToggleButtons(
            isSelected: [value == true, value == false],
            onPressed: (i) => onChanged(i == 0 ? true : false),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 32),
            textStyle: const TextStyle(fontSize: 12),
            children: const [Text('Có'), Text('Không')],
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn loại báo cáo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.flash_on,
                    title: 'Báo cáo nhanh',
                    description: 'Ca đơn lẻ/cá nhân',
                    color: Colors.red,
                    isSelected: _reportType == 'case_report',
                    onTap: () => setState(() => _reportType = 'case_report'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportTypeCard(
                    icon: Icons.assignment,
                    title: 'Chi tiết ca bệnh',
                    description: 'Đầy đủ thông tin',
                    color: Colors.deepOrange,
                    isSelected: false,
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) =>
                              const DetailedCaseReportScreen(),
                        ),
                      );
                      if (result == true) {
                        _resetForm();
                        await _showSubmitSuccessAndGoToHistory();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tạm thời chỉ hỗ trợ báo cáo ca bệnh để đảm bảo độ chính xác nghiệp vụ.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo dịch bệnh'),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Report type selector
                      _buildReportTypeSelector(),
                      const SizedBox(height: 16),

                      // Header
                      Card(
                        color: _isOutbreakAlert
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                _isOutbreakAlert
                                    ? Icons.campaign
                                    : Icons.warning_amber_rounded,
                                color: _themeColor,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reportTitle,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isOutbreakAlert
                                            ? Colors.orange.shade900
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _reportSubtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isOutbreakAlert
                                            ? Colors.orange.shade700
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Disease type dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDiseaseType,
                        decoration: InputDecoration(
                          labelText: 'Loại bệnh *',
                          prefixIcon: const Icon(Icons.coronavirus),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _diseaseTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDiseaseType = value;
                          });
                        },
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
                          labelText: 'Mô tả chi tiết *',
                          hintText: _isOutbreakAlert
                              ? 'Mô tả ổ dịch: khu vực, số ca nghi nhiễm, diễn biến...'
                              : 'Mô tả tình trạng, triệu chứng...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 4,
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.photo_library_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Ảnh minh chứng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_selectedEvidenceImages.length}/4',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                                  ..._selectedEvidenceImages.asMap().entries.map((entry) {
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
                                            onTap: () => _removeEvidenceImage(index),
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
                                    onPressed: () => _pickEvidenceImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Thư viện'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _pickEvidenceImage(ImageSource.camera),
                                    icon: const Icon(Icons.photo_camera),
                                    label: const Text('Camera'),
                                  ),
                                ],
                              ),
                            ],
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
                              Row(
                                children: [
                                  const Icon(Icons.sick, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Triệu chứng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_selectedSymptoms.length} đã chọn',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableSymptoms.map((symptom) {
                                  final isSelected = _selectedSymptoms.contains(
                                    symptom,
                                  );
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
                                    selectedColor:
                                        (_isOutbreakAlert
                                                ? Colors.orange
                                                : Colors.red)
                                            .shade100,
                                    checkmarkColor:
                                        (_isOutbreakAlert
                                                ? Colors.orange
                                                : Colors.red)
                                            .shade700,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location inputs
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: _themeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Vị trí ca bệnh *',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Reporter location indicator
                                  if (_reporterLocation != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.my_location,
                                            size: 12,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Đã lấy vị trí',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isOutbreakAlert
                                    ? 'Chọn vị trí trung tâm của ổ dịch/cụm ca bệnh'
                                    : 'Chọn vị trí nơi xảy ra ca bệnh (có thể khác vị trí hiện tại của bạn)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Quick action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _openMapPicker,
                                      icon: const Icon(Icons.map, size: 18),
                                      label: const Text('Chọn từ bản đồ'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _themeColor,
                                        side: BorderSide(
                                          color: _isOutbreakAlert
                                              ? Colors.orange.shade300
                                              : Colors.red.shade300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _reporterLocation != null
                                          ? _useCurrentLocationForCase
                                          : null,
                                      icon: const Icon(
                                        Icons.my_location,
                                        size: 18,
                                      ),
                                      label: const Text('Vị trí của tôi'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue.shade600,
                                        side: BorderSide(
                                          color: Colors.blue.shade300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Selected location display
                              if (_selectedCaseLocation != null)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Đã chọn: ${_selectedCaseLocation!.latitude.toStringAsFixed(4)}, ${_selectedCaseLocation!.longitude.toStringAsFixed(4)}',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Manual coordinate input
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: const Text(
                                  'Nhập tọa độ thủ công',
                                  style: TextStyle(fontSize: 13),
                                ),
                                leading: const Icon(
                                  Icons.edit_location_alt,
                                  size: 20,
                                ),
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _latController,
                                          decoration: InputDecoration(
                                            labelText: 'Vĩ độ (Lat)',
                                            hintText: '21.0285',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                                signed: true,
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Nhập vĩ độ';
                                            }
                                            final lat = double.tryParse(value);
                                            if (lat == null ||
                                                lat < -90 ||
                                                lat > 90) {
                                              return 'Không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _lonController,
                                          decoration: InputDecoration(
                                            labelText: 'Kinh độ (Lon)',
                                            hintText: '105.8542',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                                signed: true,
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Nhập kinh độ';
                                            }
                                            final lon = double.tryParse(value);
                                            if (lon == null ||
                                                lon < -180 ||
                                                lon > 180) {
                                              return 'Không hợp lệ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ chi tiết',
                          hintText: _isOutbreakAlert
                              ? 'Ví dụ: Trường học/khu dân cư/chợ bị ảnh hưởng...'
                              : 'Số nhà, đường, phường/xã...',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isOutbreakAlert
                                      ? 'Số ca nghi nhiễm được tự động đặt tối thiểu là 2 cho báo cáo ổ dịch.'
                                      : 'Số ca được tự động đặt là 1 cho mỗi báo cáo ca bệnh.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Severity level
                      DropdownButtonFormField<String>(
                        initialValue: _severityLevel,
                        decoration: InputDecoration(
                          labelText: _isOutbreakAlert
                              ? 'Mức độ nguy cơ ổ dịch'
                              : 'Mức độ nghiêm trọng',
                          prefixIcon: const Icon(Icons.priority_high),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Thấp')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Trung bình'),
                          ),
                          DropdownMenuItem(value: 'high', child: Text('Cao')),
                          DropdownMenuItem(
                            value: 'critical',
                            child: Text('Nghiêm trọng'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _severityLevel = v ?? 'medium'),
                      ),
                      const SizedBox(height: 16),

                      if (_isOutbreakAlert)
                        Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Nên ghi rõ mốc thời gian xuất hiện ca đầu tiên, nhóm đối tượng (trường học/khu dân cư), và phạm vi ảnh hưởng để cơ quan y tế xử lý nhanh hơn.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_isOutbreakAlert) const SizedBox(height: 16),

                      // Epidemiological info
                      if (!_isOutbreakAlert)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.biotech, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Thông tin dịch tễ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildYesNoQuestion(
                                  'Có tiếp xúc với bệnh nhân?',
                                  _hasContactWithPatient,
                                  (v) => setState(
                                    () => _hasContactWithPatient = v,
                                  ),
                                ),
                                _buildYesNoQuestion(
                                  'Có đến vùng dịch gần đây?',
                                  _hasVisitedEpidemicArea,
                                  (v) => setState(
                                    () => _hasVisitedEpidemicArea = v,
                                  ),
                                ),
                                _buildYesNoQuestion(
                                  'Có ca tương tự gần nơi ở?',
                                  _hasSimilarCasesNearby,
                                  (v) => setState(
                                    () => _hasSimilarCasesNearby = v,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!_isOutbreakAlert) const SizedBox(height: 16),

                      // Self report toggle
                      if (!_isOutbreakAlert)
                        SwitchListTile(
                          title: const Text('Tự báo cáo cho bản thân'),
                          subtitle: Text(
                            _isSelfReport
                                ? 'Bạn là người bệnh'
                                : 'Bạn báo cáo cho người khác',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          value: _isSelfReport,
                          onChanged: (v) => setState(() => _isSelfReport = v),
                          activeThumbColor: _themeColor,
                        ),

                      // Consent
                      CheckboxListTile(
                        value: _reporterConsent,
                        onChanged: (v) =>
                            setState(() => _reporterConsent = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tôi đồng ý chia sẻ thông tin này với cơ quan y tế để phục vụ giám sát dịch bệnh',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Submit button
                      ElevatedButton(
                        onPressed: (provider.isLoading || _isSubmitting)
                            ? null
                            : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send),
                            const SizedBox(width: 8),
                            Text(
                              _isOutbreakAlert
                                  ? 'Gửi cảnh báo ổ dịch'
                                  : 'Gửi báo cáo nhanh',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Note
                      Text(
                        '* Thông tin bắt buộc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (provider.isLoading || _isSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang gửi báo cáo...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Card widget for report type selection
class _ReportTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReportTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
