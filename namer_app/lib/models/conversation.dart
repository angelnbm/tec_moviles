class Message {
  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] is String 
          ? json['senderId'] 
          : json['senderId']['_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class Conversation {
  final String id;
  final String reportId;
  final Map<String, dynamic> reportData;
  final String reportAuthorId;
  final Map<String, dynamic> reportAuthorData;
  final String interestedUserId;
  final Map<String, dynamic> interestedUserData;
  final List<Message> messages;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.reportId,
    required this.reportData,
    required this.reportAuthorId,
    required this.reportAuthorData,
    required this.interestedUserId,
    required this.interestedUserData,
    required this.messages,
    required this.lastMessageAt,
    required this.createdAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Parse messages
    List<Message> messagesList = [];
    if (json['messages'] != null && json['messages'] is List) {
      messagesList = (json['messages'] as List)
          .map((msg) => Message.fromJson(msg))
          .toList();
    }

    // Parse report data
    Map<String, dynamic> reportData = {};
    if (json['reportId'] is Map) {
      reportData = Map<String, dynamic>.from(json['reportId']);
    }

    // Parse report author data
    Map<String, dynamic> reportAuthorData = {};
    if (json['reportAuthorId'] is Map) {
      reportAuthorData = Map<String, dynamic>.from(json['reportAuthorId']);
    }

    // Parse interested user data
    Map<String, dynamic> interestedUserData = {};
    if (json['interestedUserId'] is Map) {
      interestedUserData = Map<String, dynamic>.from(json['interestedUserId']);
    }

    return Conversation(
      id: json['_id'] ?? '',
      reportId: json['reportId'] is String 
          ? json['reportId'] 
          : (json['reportId']?['_id'] ?? ''),
      reportData: reportData,
      reportAuthorId: json['reportAuthorId'] is String
          ? json['reportAuthorId']
          : (json['reportAuthorId']?['_id'] ?? ''),
      reportAuthorData: reportAuthorData,
      interestedUserId: json['interestedUserId'] is String
          ? json['interestedUserId']
          : (json['interestedUserId']?['_id'] ?? ''),
      interestedUserData: interestedUserData,
      messages: messagesList,
      lastMessageAt: DateTime.parse(
          json['lastMessageAt'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reportId': reportId,
      'reportAuthorId': reportAuthorId,
      'interestedUserId': interestedUserId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }
}
