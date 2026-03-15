import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/geocoding_service.dart';

/// A widget that allows users to pick a location from a map
class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;
  final String? subtitle;
  final ValueChanged<LatLng> onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    this.title = 'Chọn vị trí',
    this.subtitle,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  late final MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  // Default to Hanoi, Vietnam
  static const LatLng _defaultCenter = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _fetchAddress(_selectedLocation!);
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = null;
    });
    _fetchAddress(point);
    widget.onLocationSelected(point);
  }

  Future<void> _fetchAddress(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
    });
    
    try {
      final result = await GeocodingService.instance.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        setState(() {
          _selectedAddress = result.formattedAddress;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.map, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.subtitle!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 12),

        // Map
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialLocation ?? _defaultCenter,
                  initialZoom: 15,
                  minZoom: 5,
                  maxZoom: 18,
                  onTap: _onTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.safezone.app',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Zoom controls
              Positioned(
                right: 8,
                bottom: 8,
                child: Column(
                  children: [
                    _MapButton(
                      icon: Icons.add,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom + 1;
                        _mapController.move(
                          _mapController.camera.center,
                          zoom.clamp(5, 18),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _MapButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom - 1;
                        _mapController.move(
                          _mapController.camera.center,
                          zoom.clamp(5, 18),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Instruction overlay
              if (_selectedLocation == null)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Chạm vào bản đồ để chọn vị trí',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Selected location info
        if (_selectedLocation != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vị trí đã chọn',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                          fontSize: 13,
                        ),
                      ),
                      if (_isLoadingAddress)
                        Text(
                          'Đang lấy địa chỉ...',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 11,
                          ),
                        )
                      else if (_selectedAddress != null)
                        Text(
                          _selectedAddress!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lon: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedLocation = null;
                      _selectedAddress = null;
                    });
                  },
                  color: Colors.green.shade700,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

/// Full-screen location picker dialog
class LocationPickerDialog extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    this.title = 'Chọn vị trí ca bệnh',
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late final MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;

  static const LatLng _defaultCenter = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _fetchAddress(_selectedLocation!);
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = null;
    });
    _fetchAddress(point);
  }

  Future<void> _fetchAddress(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
    });
    
    try {
      final result = await GeocodingService.instance.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        setState(() {
          _selectedAddress = result.formattedAddress;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _selectedLocation != null
                ? () => Navigator.of(context).pop(_selectedLocation)
                : null,
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: _selectedLocation != null
                    ? Colors.white
                    : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _defaultCenter,
              initialZoom: 15,
              minZoom: 5,
              maxZoom: 18,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.safezone.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Center crosshair
          const Center(
            child: IgnorePointer(
              child: Icon(Icons.add, size: 24, color: Colors.black38),
            ),
          ),

          // Instruction
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedLocation == null
                        ? const Text(
                            'Chạm vào bản đồ để chọn vị trí ca bệnh',
                            style: TextStyle(fontSize: 13),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isLoadingAddress)
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Đang lấy địa chỉ...',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                )
                              else if (_selectedAddress != null)
                                Text(
                                  _selectedAddress!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lon: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                  if (_selectedLocation != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _selectedLocation = null;
                          _selectedAddress = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(5, 18),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(5, 18),
                    );
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
