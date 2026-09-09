class ProFaqModel {
  int? id;
  String? question;
  String? answer;
  int? priority;

  ProFaqModel({
    this.id,
    this.question,
    this.answer,
    this.priority,
  });

  ProFaqModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    question = json['question'];
    answer = json['answer'];
    priority = json['priority'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['question'] = question;
    data['answer'] = answer;
    data['priority'] = priority;
    return data;
  }
}
