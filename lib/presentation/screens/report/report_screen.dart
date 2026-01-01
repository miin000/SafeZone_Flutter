import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/report_model.dart';
import '../../providers/report_provider.dart';

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
  final _affectedCountController = TextEditingController(text: '1');
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  
  // Form state
  String? _selectedDiseaseType;
  final List<String> _selectedSymptoms = [];
  
  // Disease types
  final List<String> _diseaseTypes = [
    'Sốt xuất huyết',
    'Tay chân miệng',
    'COVID-19',
    'Cúm mùa',
    'Sởi',
    'Thủy đậu',
    'Tiêu chảy cấp',
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
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _affectedCountController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
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

    final request = CreateReportRequest(
      diseaseType: _selectedDiseaseType!,
      description: _descriptionController.text.trim(),
      lat: lat,
      lon: lon,
      address: _addressController.text.trim().isNotEmpty 
          ? _addressController.text.trim() 
          : null,
      symptoms: _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      affectedCount: int.tryParse(_affectedCountController.text),
    );

    final provider = context.read<ReportProvider>();
    final success = await provider.createReport(request);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi báo cáo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _descriptionController.clear();
    _addressController.clear();
    _affectedCountController.text = '1';
    _latController.clear();
    _lonController.clear();
    setState(() {
      _selectedDiseaseType = null;
      _selectedSymptoms.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo dịch bệnh'),
        backgroundColor: Colors.red.shade600,
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
                      // Header
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, 
                                   color: Colors.red.shade600, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Báo cáo ca bệnh',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Thông tin sẽ được xác minh bởi cơ quan y tế',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
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
                        value: _selectedDiseaseType,
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
                          hintText: 'Mô tả tình trạng, triệu chứng...',
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
                                    selectedColor: Colors.red.shade100,
                                    checkmarkColor: Colors.red.shade700,
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
                              const Row(
                                children: [
                                  Icon(Icons.location_on, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Vị trí *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _latController,
                                      decoration: InputDecoration(
                                        labelText: 'Vĩ độ (Lat)',
                                        hintText: '21.0285',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Nhập vĩ độ';
                                        }
                                        final lat = double.tryParse(value);
                                        if (lat == null || lat < -90 || lat > 90) {
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
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Nhập kinh độ';
                                        }
                                        final lon = double.tryParse(value);
                                        if (lon == null || lon < -180 || lon > 180) {
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ chi tiết',
                          hintText: 'Số nhà, đường, phường/xã...',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Affected count
                      TextFormField(
                        controller: _affectedCountController,
                        decoration: InputDecoration(
                          labelText: 'Số người bị ảnh hưởng',
                          prefixIcon: const Icon(Icons.people),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final count = int.tryParse(value);
                            if (count == null || count < 1) {
                              return 'Số người phải >= 1';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: provider.isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Gửi báo cáo',
                              style: TextStyle(
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
              if (provider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
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

