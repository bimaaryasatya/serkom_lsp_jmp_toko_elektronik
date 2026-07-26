import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class ProductManagePage extends StatefulWidget {
  const ProductManagePage({super.key});

  @override
  State<ProductManagePage> createState() => _ProductManagePageState();
}

class _ProductManagePageState extends State<ProductManagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  void _showAddEditDialog({ProductModel? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController =
        TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '');
    final imageController = TextEditingController(text: product?.image ?? '');
    final categoryController =
        TextEditingController(text: product?.category ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration:
                      const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'URL Gambar'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: categoryController,
                  decoration:
                      const InputDecoration(labelText: 'Kategori'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final newProduct = ProductModel(
                id: product?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: nameController.text,
                description: descController.text,
                price: double.parse(priceController.text),
                stock: int.parse(stockController.text),
                image: imageController.text,
                category: categoryController.text,
              );

              if (product == null) {
                context.read<ProductProvider>().addProduct(newProduct);
              } else {
                context.read<ProductProvider>().updateProduct(newProduct);
              }

              Navigator.pop(ctx);
            },
            child: Text(product == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkron dari DummyJSON',
            onPressed: () async {
              try {
                await context.read<ProductProvider>().loadProducts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sinkronisasi berhasil'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return const Center(
              child: Text('Belum ada produk. Sinkronkan atau tambah manual.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const CircularProgressIndicator(
                                strokeWidth: 2),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Stok: ${product.stock} | ${product.category}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showAddEditDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20,
                            color: Colors.red),
                        onPressed: () => _confirmDelete(product),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
