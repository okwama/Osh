import 'package:get/get.dart';
import 'package:woosh/services/core/product_service.dart';
import 'package:woosh/models/Products_Inventory/product_model.dart';

class ProductController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasMoreProducts = true.obs;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    print('🔍 ProductController initialized');
  }

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
    int? clientId,
    bool? inStock,
    int? countryId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print(
          '🔍 Getting products: page=$page, limit=$limit, search=$search, category=$categoryId, client=$clientId, inStock=$inStock, country=$countryId');

      final result = await ProductService.getProducts(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
        clientId: clientId,
        inStock: inStock,
        countryId: countryId,
      );

      if (page == 1) {
        products.value = result;
      } else {
        products.addAll(result);
      }

      _currentPage = page;
      hasMoreProducts.value = result.length == limit;

      print(
          '✅ Products loaded: ${result.length} items, hasMore=${hasMoreProducts.value}');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to load products: $e';
      print('❌ Error loading products: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<ProductModel?> getProductById(int productId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Getting product by ID: $productId');

      final result = await ProductService.getProductById(productId);

      print('✅ Product retrieved: ${result?.name}');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to get product: $e';
      print('❌ Error getting product: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔍 Searching products: $query');

      final result = await ProductService.searchProducts(query);

      print('✅ Product search completed: ${result.length} results');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to search products: $e';
      print('❌ Error searching products: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }

  void resetPagination() {
    _currentPage = 1;
    hasMoreProducts.value = true;
  }
}
