// lib/models/answer.dart

/// 定义了用户答案的数据模型。
///
/// 这个类包含了与答案相关的核心信息，例如问题ID、答案内容、提交日期以及贡献者列表。
/// 它还提供了从 Map 转换和转换为 Map 的方法，以便于数据的序列化和反序列化。
class Answer {
  /// 对应问题的唯一标识符。
  final String? questionId;

  /// 用户提交的答案内容。
  final String? answer;

  /// 答案提交的日期和时间。
  final DateTime? date;

  /// 对此答案有贡献的用户列表。
  final List<String>? contributors;

  Answer({
    this.questionId,
    this.answer,
    this.date,
    this.contributors,
  });

  /// 从 Map 对象创建 [Answer] 实例的工厂构造函数。
  ///
  /// 这对于从 JSON 或数据库记录反序列化数据非常有用。
  /// [map] 包含了答案的属性。
  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      questionId: map['question_id'],
      answer: map['answer'],
      date: map['date'] == null ? null : DateTime.parse(map['date']),
      contributors: map['contributors'] == null
          ? null
          : List<String>.from(map['contributors']),
    );
  }

  /// 将 [Answer] 实例转换为 Map 对象。
  ///
  /// 这对于将数据序列化为 JSON 或存入数据库非常有用。
  Map<String, dynamic> toMap() {
    return {
      'question_id': questionId,
      'answer': answer,
      'date': date?.toIso8601String(), // 将 DateTime 转换为 ISO 8601 字符串以便序列化。
      'contributors': contributors,
    };
  }

  /// 创建当前 [Answer] 对象的副本，并可以替换指定的属性。
  ///
  /// 这遵循了不可变数据模式，使得状态管理更安全、可预测。
  Answer copyWith({
    String? questionId,
    String? answer,
    DateTime? date,
    List<String>? contributors,
  }) {
    return Answer(
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      date: date ?? this.date,
      contributors: contributors ?? this.contributors,
    );
  }
}
