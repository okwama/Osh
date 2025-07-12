import 'package:get/get.dart';
import 'package:woosh/services/core/upload_service.dart';
import 'dart:io';

class UploadController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString uploadProgress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 UploadController initialized');
  }

  Future<Map<String, dynamic>?> uploadImage(File imageFile) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      uploadProgress.value = 'Uploading image...';
      print('🔍 Uploading image: ${imageFile.path}');

      final result = await UploadService.uploadImage(imageFile);

      uploadProgress.value = '';
      print('✅ Image uploaded successfully');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to upload image: $e';
      uploadProgress.value = '';
      print('❌ Error uploading image: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> uploadDocument(File documentFile) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      uploadProgress.value = 'Uploading document...';
      print('🔍 Uploading document: ${documentFile.path}');

      final result = await UploadService.uploadFile(documentFile, folder: 'documents');

      uploadProgress.value = '';
      print('✅ Document uploaded successfully');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to upload document: $e';
      uploadProgress.value = '';
      print('❌ Error uploading document: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> uploadFile(File file, {String? folder}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      uploadProgress.value = 'Uploading file...';
      print('🔍 Uploading file: ${file.path}, folder: $folder');

      final result = await UploadService.uploadFile(file, folder: folder);

      uploadProgress.value = '';
      print('✅ File uploaded successfully');
      return result;
    } catch (e) {
      errorMessage.value = 'Failed to upload file: $e';
      uploadProgress.value = '';
      print('❌ Error uploading file: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
