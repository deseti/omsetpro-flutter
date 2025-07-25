class ProductFilterHelper {
  static List<dynamic> filterProducts(List<dynamic> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    final searchQuery = query.toLowerCase();
    return products.where((produk) {
      final nama = produk['nama'].toString().toLowerCase();
      final barcode = produk['barcode']?.toString().toLowerCase() ?? '';
      return nama.contains(searchQuery) || barcode.contains(searchQuery);
    }).toList();
  }
}
