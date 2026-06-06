class NotificationModel {
  final String id;
  final String? userId; // If null, it's a broadcast
  final String title;
  final String message;
  final String type; // 'article' or 'out_of_zone'
  final bool isRead;
  final DateTime date;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.date,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      isRead: json['is_read'] == true,
      date: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': date.toIso8601String(),
    };
  }
}
