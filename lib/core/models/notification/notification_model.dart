class NotificationModel {
  List<Notifications>? data;

  NotificationModel({
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    data: json["data"] == null ? [] : List<Notifications>.from(json["data"]!.map((x) => Notifications.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Notifications {
  int? id;
  String? title;
  String? description;
  DateTime? dateTime;
  bool? isRead;

  Notifications({
    this.id,
    this.title,
    this.description,
    this.dateTime,
    this.isRead,
  });

  factory Notifications.fromJson(Map<String, dynamic> json) => Notifications(
    id: json["id"],
    title: json["title"],
    description: json["description"],
    isRead: json["isRead"],
    dateTime: DateTime.parse(json["date_time"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "date_time": dateTime,
    "isRead": isRead,
  };
}