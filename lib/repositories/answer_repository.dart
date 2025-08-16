// lib/repositories/answer_repository.dart

import 'dart:io';
import 'package:eauxiliary/models/folder_item.dart';
import 'package:eauxiliary/services/file_service.dart';
import 'package:eauxiliary/utils/simple_storage.dart';

/// `AnswerRepository` 是数据仓库层，负责协调和封装与“答案”相关的数据操作。
///
/// 它作为领域层（例如 `AnswerProvider`）和数据源（如 `FileService`、`ApiService`、
/// `SecureStorage`）之间的桥梁。其主要职责是向上层提供一个统一、简洁的数据访问接口，
/// 而将具体的数据获取、存储和处理逻辑委托给下层的服务。
///
/// 注意: 当前实现主要作为代理，直接调用底层服务的静态方法。
/// 随着业务逻辑变得更复杂，这个类可以扩展为包含更多的数据处理、
/// 缓存策略或数据合并逻辑。为了提高可测试性，未来也可以考虑使用依赖注入
/// 来管理 `FileService` 和 `ApiService` 的实例。
class AnswerRepository {
  /// 从 `FileService` 获取排序后的资源文件夹列表。
  Future<List<FolderItem>> getSortedResourceFolders() {
    return FileService.getSortedResourceFolders();
  }

  /// 委托 `FileService` 按时间对资源文件夹进行分组。
  List<List<FolderItem>> groupResourceFoldersByTime(List<FolderItem> folders) {
    return FileService.groupResourceFoldersByTime(folders);
  }

  /// 委托 `FileService` 根据用户类型过滤文件夹组。
  List<List<FolderItem>> filterFolderGroups(
    List<List<FolderItem>> groupedFolders,
    String userType,
  ) {
    return FileService.filterFolderGroups(groupedFolders, true, userType);
  }

  /// 委托 `FileService` 对文件夹组进行最终的标记和整理。
  List<({List<FolderItem> group, String tag})> markAndFilterGroups(
      List<List<FolderItem>> groupedFolders) {
    return FileService.markAndFilterGroups(groupedFolders);
  }

  /// 委托 `FileService` 从给定的文件夹组中读取答案。
  Future<String> getAnswersFromFolderGroup(List<FolderItem> group) {
    return FileService.getAnswersFromFolderGroup(group);
  }

  /// 委托 `FileService` 获取本地存储的学生姓名。
  Future<String?> getStudentName() {
    return FileService.getStudentName();
  }

  /// 委托 `SimpleStorage` 从缓存中读取答案。
  Future<String?> getCachedAnswers(List<File> group) async {
    return SimpleStorage.getCachedAnswers(group);
  }

  /// 委托 `SimpleStorage` 将答案缓存到存储中。
  Future<void> cacheAnswers(List<File> group, String answers) async {
    return SimpleStorage.cacheAnswers(group, answers);
  }
}
