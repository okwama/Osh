import 'package:get/get.dart';
import 'package:woosh/models/task_model.dart';
import 'package:woosh/services/core/task_service.dart';

class TaskController extends GetxController {
  final RxList<Task> tasks = <Task>[].obs;
  final RxList<Task> taskHistory = <Task>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
    loadTaskHistory();
  }

  Future<void> loadTasks() async {
    try {
      isLoading.value = true;
      final taskList = await TaskService.getTasks();
      tasks.value = taskList;
    } catch (e) {
      print('❌ Error loading tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTaskHistory() async {
    try {
      final history = await TaskService.getTaskHistory();
      taskHistory.value = history;
    } catch (e) {
      print('❌ Error loading task history: $e');
    }
  }

  Future<bool> completeTask(int taskId) async {
    try {
      final success = await TaskService.completeTask(taskId);
      if (success) {
        // Reload tasks after completion
        await loadTasks();
        await loadTaskHistory();
      }
      return success;
    } catch (e) {
      print('❌ Error completing task: $e');
      return false;
    }
  }
}
