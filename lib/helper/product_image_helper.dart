import 'package:sixam_mart/util/app_constants.dart';

class ProductImageHelper {
  const ProductImageHelper._();

  static String? fullUrl(dynamic image) {
    final String? name = image?.toString();
    // Already absolute, or nothing to resolve — a bundle member with no picture keeps
    // its empty string so the group still shows a slot for it.
    if(name == null || name.isEmpty || name.startsWith('http')) {
      return name;
    }
    return '${AppConstants.baseUrl}/storage/app/public/product/$name';
  }
}

// SUMMARY
// Resolves a product image as the API sends it — a bare file name on bundle members,
// an absolute URL elsewhere — into a URL the image widgets can load.
