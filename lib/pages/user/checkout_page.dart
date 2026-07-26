import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'map_picker_page.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../repositories/transaction_repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  bool _isProcessing = false;
  bool _isLocating = false;
  double _shippingFee = 0.0;
  String? _gpsLocationInfo;

  // Koordinat Gudang Utama Toko Elektronik (Contoh: Monas Jakarta -6.175392, 106.827153)
  static const double _storeLatitude = -6.175392;
  static const double _storeLongitude = 106.827153;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Fungsi Deteksi Lokasi GPS menggunakan Plugin Geolocator
  Future<void> _detectGpsLocation() async {
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
                timeLimit: Duration(seconds: 15),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Geolocator error: $e');
      }

      // Gunakan posisi GPS asli dari laptop/HP jika berhasil didapatkan
      double lat = position?.latitude ?? -6.200000;
      double lon = position?.longitude ?? 106.816667;

      // Hitung Jarak dari Gudang Toko ke Posisi Pengguna (menggunakan Geolocator.distanceBetween)
      double distanceInMeters = Geolocator.distanceBetween(
        _storeLatitude,
        _storeLongitude,
        lat,
        lon,
      );

      double distanceInKm = distanceInMeters / 1000;

      // Hitung Tarif Ongkir berdasarkan Jarak GPS
      double calculatedFee = 10000; // Tarif dasar <= 5 km
      if (distanceInKm > 30) {
        calculatedFee = 50000;
      } else if (distanceInKm > 15) {
        calculatedFee = 35000;
      } else if (distanceInKm > 5) {
        calculatedFee = 20000;
      }

      setState(() {
        _shippingFee = calculatedFee;
        _gpsLocationInfo =
            'GPS: Lat ${lat.toStringAsFixed(4)}, Lon ${lon.toStringAsFixed(4)} (Jarak: ${distanceInKm.toStringAsFixed(1)} km dari Gudang)';
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'Jl. Jenderal Sudirman No. 123 (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi GPS Terdeteksi! Jarak ${distanceInKm.toStringAsFixed(1)} km. Ongkir: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(calculatedFee)}',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal deteksi GPS: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _processCheckout() async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Silakan isi Alamat Pengiriman atau gunakan tombol Deteksi GPS',
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final double totalPayment = cartProvider.totalPrice + _shippingFee;
      String fullAddressDetail = _addressController.text.trim();
      if (_gpsLocationInfo != null) {
        fullAddressDetail += ' | $_gpsLocationInfo';
      }

      final transactionRepo = TransactionRepository();
      await transactionRepo.createTransaction(
        userId: authProvider.user!.id!,
        total: totalPayment,
        shippingFee: _shippingFee,
        address: fullAddressDetail,
        cartItems: cartProvider.cartItems,
        products: cartProvider.products,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pembayaran berhasil! Pesanan menunggu konfirmasi penjual.',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal checkout: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      double lat = result['lat'];
      double lng = result['lng'];
      double distanceKm = result['distanceKm'];
      double fee = result['shippingFee'];

      setState(() {
        _shippingFee = fee;
        _gpsLocationInfo = 'Peta GPS: Lat ${lat.toStringAsFixed(5)}, Lon ${lng.toStringAsFixed(5)} (Jarak: ${distanceKm.toStringAsFixed(1)} km dari Gudang)';
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = 'Jl. Pengiriman Terpilih (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pembayaran & Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          final double subtotal = cartProvider.totalPrice;
          final double grandTotal = subtotal + _shippingFee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alamat & Deteksi GPS Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Alamat Pengiriman',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openMapPicker,
                                icon: const Icon(Icons.map_outlined, size: 14, color: Color(0xFF2563EB)),
                                label: const Text('Pilih di Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isLocating ? null : _detectGpsLocation,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.my_location, size: 14),
                                label: Text(
                                  _isLocating ? 'Mendeteksi...' : 'GPS Saya',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Tulis alamat lengkap pengiriman di sini...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (_gpsLocationInfo != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _gpsLocationInfo!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ringkasan Produk Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...cartProvider.cartItems.map((cartItem) {
                        final product = cartProvider.getProductById(
                          cartItem.productId,
                        );
                        if (product == null) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${product.name} x${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormat.format(
                                  product.price * cartItem.quantity,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal Produk',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            currencyFormat.format(subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ongkos Kirim (Berdasarkan GPS)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _shippingFee == 0
                                ? 'Gunakan Deteksi GPS'
                                : currencyFormat.format(_shippingFee),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _shippingFee == 0
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            currencyFormat.format(grandTotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metode Pembayaran Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pembayaran',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(
                          Icons.account_balance,
                          color: Color(0xFF2563EB),
                        ),
                        title: Text(
                          'Transfer Bank BCA / Mandiri',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '1234567890 a.n. Toko Elektronik',
                          style: TextStyle(fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.account_balance_wallet,
                          color: Color(0xFF10B981),
                        ),
                        title: Text(
                          'E-Wallet (DANA / GoPay / OVO)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '081234567890',
                          style: TextStyle(fontSize: 11),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _processCheckout,
            icon: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isProcessing ? 'Memproses...' : 'Konfirmasi & Bayar Sekarang',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}
