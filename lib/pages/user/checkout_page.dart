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

  String _selectedPayment = 'Transfer Bank BCA / Mandiri';
  String _selectedCourier = 'JNE Regular';

  static const double _storeLatitude = -6.175392;
  static const double _storeLongitude = 106.827153;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

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
      } catch (_) {}

      double lat = position?.latitude ?? -6.200000;
      double lon = position?.longitude ?? 106.816667;

      double distanceInMeters = Geolocator.distanceBetween(_storeLatitude, _storeLongitude, lat, lon);
      double distanceInKm = distanceInMeters / 1000;

      double calculatedFee = 10000;
      if (distanceInKm > 30) {
        calculatedFee = 50000;
      } else if (distanceInKm > 15) {
        calculatedFee = 35000;
      } else if (distanceInKm > 5) {
        calculatedFee = 20000;
      }

      setState(() {
        _shippingFee = calculatedFee;
        _gpsLocationInfo = 'GPS: Lat ${lat.toStringAsFixed(4)}, Lon ${lon.toStringAsFixed(4)} (${distanceInKm.toStringAsFixed(1)} km dari Gudang)';
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = 'Jl. Jenderal Sudirman No. 123 (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _processCheckout() async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi Alamat Pengiriman')),
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
        paymentMethod: _selectedPayment,
        courier: _selectedCourier,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat! Menunggu konfirmasi penjual.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal checkout: $e')),
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
        _gpsLocationInfo = 'Peta: Lat ${lat.toStringAsFixed(5)}, Lon ${lng.toStringAsFixed(5)} (${distanceKm.toStringAsFixed(1)} km)';
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = 'Alamat Peta (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran & Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          final double subtotal = cartProvider.totalPrice;
          final double grandTotal = subtotal + _shippingFee;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alamat Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('Alamat Pengiriman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openMapPicker,
                                icon: Icon(Icons.map_outlined, size: 14, color: cs.primary),
                                label: Text('Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isLocating ? null : _detectGpsLocation,
                                icon: _isLocating
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.my_location, size: 14),
                                label: Text(_isLocating ? 'GPS...' : 'GPS Saya'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Tulis alamat lengkap pengiriman di sini...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kurir Pengiriman Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih Kurir Pengiriman 🚚', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCourier,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        items: const [
                          DropdownMenuItem(value: 'JNE Regular', child: Text('JNE Regular')),
                          DropdownMenuItem(value: 'J&T Express', child: Text('J&T Express')),
                          DropdownMenuItem(value: 'Pos Indonesia', child: Text('Pos Indonesia Next Day')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCourier = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metode Pembayaran Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Metode Pembayaran 💳', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 10),
                      RadioListTile<String>(
                        title: const Text('Transfer Bank BCA / Mandiri'),
                        subtitle: const Text('1234567890 a.n. Toko Elektronik'),
                        value: 'Transfer Bank BCA / Mandiri',
                        groupValue: _selectedPayment,
                        onChanged: (val) => setState(() => _selectedPayment = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('QRIS All Payment'),
                        subtitle: const Text('Scan QR setelah pesanan dikonfirmasi'),
                        value: 'QRIS All Payment',
                        groupValue: _selectedPayment,
                        onChanged: (val) => setState(() => _selectedPayment = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Cash on Delivery (COD)'),
                        subtitle: const Text('Bayar langsung ke kurir saat barang tiba'),
                        value: 'Cash on Delivery (COD)',
                        groupValue: _selectedPayment,
                        onChanged: (val) => setState(() => _selectedPayment = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ringkasan Pesanan Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ringkasan Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal Produk', style: TextStyle(color: cs.onSurfaceVariant)),
                          Text(currencyFormat.format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ongkos Kirim ($_selectedCourier)', style: TextStyle(color: cs.onSurfaceVariant)),
                          Text(
                            currencyFormat.format(_shippingFee),
                            style: TextStyle(fontWeight: FontWeight.bold, color: cs.tertiary),
                          ),
                        ],
                      ),
                      Divider(height: 20, color: cs.outline),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                          Text(
                            currencyFormat.format(grandTotal),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary),
                          ),
                        ],
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
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(_isProcessing ? 'Memproses...' : 'Konfirmasi & Buat Pesanan'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ),
      ),
    );
  }
}
