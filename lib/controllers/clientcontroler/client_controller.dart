import 'package:get/get.dart';
import 'package:woosh/models/client/client_model.dart';
import 'package:woosh/services/core/client_repository.dart';

class ClientController extends GetxController {
  final RxList<Client> clients = <Client>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt currentPage = 1.obs;
  final int pageSize = 20;
  int? routeId;
  int? countryId;

  // Repository instance - abstracts database operations
  late final ClientRepository _clientRepository;

  @override
  void onInit() {
    super.onInit();
    _clientRepository = ClientRepository.instance;
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      currentPage.value = 1;
      hasMore.value = true;

      final result = await _clientRepository.getClients(
        page: currentPage.value,
        limit: pageSize,
        routeId: routeId,
        countryId: countryId,
        orderBy: 'id',
        orderDirection: 'DESC',
      );

      clients.value = result.items;
      hasMore.value = result.hasMore;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load clients. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;

    try {
      isLoading.value = true;
      currentPage.value++;

      final result = await _clientRepository.getClients(
        page: currentPage.value,
        limit: pageSize,
        routeId: routeId,
        countryId: countryId,
        orderBy: 'id',
        orderDirection: 'DESC',
      );

      clients.addAll(result.items);
      hasMore.value = result.hasMore;
    } catch (e) {
      currentPage.value--; // Revert page number on error
      Get.snackbar(
        'Error',
        'Failed to load more clients. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadInitialData();
  }

  void setRouteId(int? id) {
    routeId = id;
    loadInitialData();
  }
}