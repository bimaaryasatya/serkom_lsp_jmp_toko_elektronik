import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerPage({
    super.key,
    this.initialLocation = const LatLng(-6.175392, 106.827153), // Monas Jakarta
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _selectedLocation;
  bool _isLocating = false;

  // Koordinat Gudang Utama Toko (Monas Jakarta)
  static const LatLng _storeLocation = LatLng(-6.175392, 106.827153);

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  // Hitung Jarak Jarak dari Gudang ke Lokasi Terpilih (km)
  double get _calculatedDistanceKm {
    double meters = Geolocator.distanceBetween(
      _storeLocation.latitude,
      _storeLocation.longitude,
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );
    return meters / 1000;
  }

  // Hitung Tarif Ongkir berdasarkan Jarak
  double get _calculatedShippingFee {
    double dist = _calculatedDistanceKm;
    if (dist > 30) return 50000;
    if (dist > 15) return 35000;
    if (dist > 5) return 20000;
    return 10000;
  }

  // Fungsi Deteksi GPS dengan Geolocator
  Future<void> _detectMyLocation() async {
    setState(() => _isLocating = true);
    try {
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.deniedForever) {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 10),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Geolocator error: $e');
      }

      double lat = position?.latitude ?? -6.200000;
      double lon = position?.longitude ?? 106.816667;
      LatLng newPos = LatLng(lat, lon);

      setState(() {
        _selectedLocation = newPos;
      });

      _mapController.move(newPos, 15.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi GPS Terdeteksi: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Lokasi Tujuan di Peta',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF2563EB)),
            tooltip: 'Deteksi GPS Saya',
            onPressed: _isLocating ? null : _detectMyLocation,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap OpenStreetMap Component
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aplikasi_toko_elektronik',
              ),
              // Marker Gudang Toko Utama
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 50,
                    height: 50,
                    child: const Column(
                      children: [
                        Icon(Icons.store, color: Color(0xFF2563EB), size: 32),
                        Text('Toko', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                  // Marker Lokasi Tujuan Terpilih (Pin)
                  Marker(
                    point: _selectedLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFEF4444),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Action Button: Deteksi GPS Saya
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'detectGpsBtn',
              onPressed: _isLocating ? null : _detectMyLocation,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: _isLocating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.gps_fixed),
              label: Text(_isLocating ? 'Mendeteksi...' : 'GPS Saya'),
            ),
          ),

          // Card Informasi Latitude, Longitude & Ongkir di Bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.map_outlined, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Koordinat Lokasi Terpilih',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Display Latitude & Longitude Live!
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Latitude (Garis Lintang)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                _selectedLocation.latitude.toStringAsFixed(6),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Longitude (Garis Bujur)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                _selectedLocation.longitude.toStringAsFixed(6),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Display Jarak & Ongkir
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Jarak: ${_calculatedDistanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        'Ongkir: ${currencyFormat.format(_calculatedShippingFee)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Button Simpan & Konfirmasi Lokasi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, {
                          'lat': _selectedLocation.latitude,
                          'lng': _selectedLocation.longitude,
                          'distanceKm': _calculatedDistanceKm,
                          'shippingFee': _calculatedShippingFee,
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Gunakan Lokasi Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
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
}
