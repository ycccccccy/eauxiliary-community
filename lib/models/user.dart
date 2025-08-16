// lib/models/user.dart

/// 用户类型枚举，用于区分不同权限或状态的用户。
enum UserType {
  /// 黑名单用户，可能受到功能限制。
  blacklist,

  /// 白名单用户，可能拥有特殊权限。
  whitelist,

  /// 普通用户。
  normal,
}

/// 定义了用户的数据模型。
///
/// 此类包含用户的基本信息，如学生姓名和用户类型。
class User {
  /// 学生的姓名，可以为空。
  final String? studentName;

  /// 用户的类型，如黑名单、白名单或普通用户。
  final UserType userType;

  User({
    this.studentName,
    required this.userType,
  });

  /// 从 Map 对象创建 [User] 实例的工厂构造函数。
  ///
  /// 这对于从 JSON 或数据库记录反序列化数据非常有用。
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      studentName: map['studentName'],
      userType: UserType.values.firstWhere(
        (element) => element.toString() == 'UserType.${map['userType']}',
        orElse: () => UserType.normal,
      ),
    );
  }

  /// 将 [User] 实例转换为 Map 对象。
  ///
  /// 这对于将数据序列化为 JSON 或存入数据库非常有用。
  Map<String, dynamic> toMap() {
    return {
      'studentName': studentName,
      'userType': userType.toString().split('.').last, // 存储枚举的字符串值
    };
  }

  /// 创建当前 [User] 对象的副本，并可以替换指定的属性。
  ///
  /// 遵循不可变数据模式，使得状态管理安全可预测。
  User copyWith({
    String? studentName,
    UserType? userType,
  }) {
    return User(
      studentName: studentName ?? this.studentName,
      userType: userType ?? this.userType,
    );
  }
}
