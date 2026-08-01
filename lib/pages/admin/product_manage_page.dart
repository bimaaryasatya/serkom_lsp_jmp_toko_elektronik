import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_helper;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_image.dart';

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
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final urlInputController = TextEditingController();
    final categoryController = TextEditingController(text: product?.category ?? '');
    final formKey = GlobalKey<FormState>();

    final List<String> currentImages = List<String>.from(product?.imageList ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickImageFiles() async {
            try {
              final result = await FilePicker.pickFiles(
                type: FileType.image,
                allowMultiple: true,
              );

              if (result != null && result.files.isNotEmpty) {
                final appDir = await getApplicationDocumentsDirectory();
                for (var file in result.files) {
                  if (file.path != null && file.path!.isNotEmpty) {
                    final originalFile = File(file.path!);
                    if (await originalFile.exists()) {
                      final fileName =
                          'img_${DateTime.now().millisecondsSinceEpoch}_${path_helper.basename(file.path!)}';
                      final savedFile = await originalFile.copy(path_helper.join(appDir.path, fileName));
                      setDialogState(() {
                        currentImages.add(savedFile.path);
                      });
                    }
                  }
                }
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Gagal memilih file: $e'), backgroundColor: Colors.red),
                );
              }
            }
          }

          void addUrlImage() {
            final url = urlInputController.text.trim();
            if (url.isNotEmpty) {
              setDialogState(() {
                currentImages.add(url);
                urlInputController.clear();
              });
            }
          }

          return AlertDialog(
            title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nama Produk'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Deskripsi'),
                        maxLines: 3,
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'Stok'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Kategori (contoh: laptops, smartphones)'),
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Foto Produk (${currentImages.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Image Preview List
                      if (currentImages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada gambar ditambahkan',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: currentImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ProductImage(
                                        imageUrl: currentImages[index],
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          currentImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Buttons to add image (Upload File & URL)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: pickImageFiles,
                              icon: const Icon(Icons.add_photo_alternate, size: 18),
                              label: const Text('Pilih File Gambar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: urlInputController,
                              decoration: const InputDecoration(
                                labelText: 'Tambah URL Gambar Eksternal',
                                hintText: 'https://...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: addUrlImage,
                            child: const Text('Tambah'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                  if (urlInputController.text.trim().isNotEmpty) {
                    currentImages.add(urlInputController.text.trim());
                  }

                  final primaryImage = currentImages.isNotEmpty ? currentImages.first : '';

                  final newProduct = ProductModel(
                    id: product?.id ?? DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    price: double.parse(priceController.text.trim()),
                    stock: int.parse(stockController.text.trim()),
                    image: primaryImage,
                    images: currentImages,
                    category: categoryController.text.trim(),
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
          );
        },
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
                  leading: ProductImage(
                    imageUrl: product.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
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
