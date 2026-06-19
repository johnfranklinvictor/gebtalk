class Folder {
  final String id;
  final String name;
  final String color;

  Folder({required this.id, required this.name, required this.color});

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#3b82f6',
    );
  }
}

class Tag {
  final String id;
  final String name;
  final String color;

  Tag({required this.id, required this.name, required this.color});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#3b82f6',
    );
  }
}

class Contact {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String avatar;
  final String status;
  final String folder;
  final int unreadCount;
  final String? assignedStaffId;
  final List<Tag> tags;
  final String? email;
  final String? notes;
  final String? countryCode;
  final Message? lastMessage;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.avatar,
    required this.status,
    required this.folder,
    required this.unreadCount,
    this.assignedStaffId,
    required this.tags,
    this.email,
    this.notes,
    this.countryCode,
    this.lastMessage,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    var tagsList = json['tags'] as List? ?? [];
    List<Tag> parsedTags = tagsList.map((t) => Tag.fromJson(t)).toList();

    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'] ?? '',
      status: json['status'] ?? '',
      folder: json['folder'] ?? 'all',
      unreadCount: json['unread_count'] ?? 0,
      assignedStaffId: json['assigned_staff_id'],
      tags: parsedTags,
      email: json['email'],
      notes: json['notes'],
      countryCode: json['country_code'],
      lastMessage: json['last_message'] != null ? Message.fromJson(json['last_message']) : null,
    );
  }

  Contact copyWith({
    String? folder,
    List<Tag>? tags,
    int? unreadCount,
    String? assignedStaffId,
    String? email,
    String? notes,
    String? countryCode,
    Message? lastMessage,
  }) {
    return Contact(
      id: id,
      name: name,
      phone: phone,
      role: role,
      avatar: avatar,
      status: status,
      folder: folder ?? this.folder,
      unreadCount: unreadCount ?? this.unreadCount,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      tags: tags ?? this.tags,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      countryCode: countryCode ?? this.countryCode,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class Message {
  final int id;
  final String contactId;
  final String text;
  final bool isUser;
  final String time;
  final bool isAudio;
  final String? duration;
  final bool isFile;
  final String? fileName;
  final String? fileSize;
  final List<String> reactions;
  final String status;

  Message({
    required this.id,
    required this.contactId,
    required this.text,
    required this.isUser,
    required this.time,
    required this.isAudio,
    this.duration,
    required this.isFile,
    this.fileName,
    this.fileSize,
    required this.reactions,
    required this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    var reactionsList = json['reactions'] as List? ?? [];
    List<String> parsedReactions = reactionsList.map((r) => r.toString()).toList();

    return Message(
      id: json['id'] ?? 0,
      contactId: json['contact_id'] ?? '',
      text: json['text'] ?? '',
      isUser: json['is_user'] == 1 || json['is_user'] == true,
      time: json['time'] ?? '',
      isAudio: json['is_audio'] == 1 || json['is_audio'] == true,
      duration: json['duration'],
      isFile: json['is_file'] == 1 || json['is_file'] == true,
      fileName: json['file_name'],
      fileSize: json['file_size'],
      reactions: parsedReactions,
      status: json['status'] ?? 'sent',
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String avatar;
  final String email;
  final bool notificationsEnabled;
  final bool notificationSound;
  final bool notificationVibration;
  final bool security2fa;
  final bool readReceipts;
  final bool lastSeenVisible;
  final String countryCode;
  final String countryName;
  final String countryFlag;
  final String createdAt;
  final String verificationStatus;

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.avatar,
    required this.email,
    required this.notificationsEnabled,
    required this.notificationSound,
    required this.notificationVibration,
    required this.security2fa,
    required this.readReceipts,
    required this.lastSeenVisible,
    this.countryCode = '',
    this.countryName = '',
    this.countryFlag = '',
    this.createdAt = '',
    this.verificationStatus = 'Verified',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
      notificationsEnabled: json['notifications_enabled'] == true || json['notifications_enabled'] == 1,
      notificationSound: json['notification_sound'] == true || json['notification_sound'] == 1,
      notificationVibration: json['notification_vibration'] == true || json['notification_vibration'] == 1,
      security2fa: json['security_2fa'] == true || json['security_2fa'] == 1,
      readReceipts: json['read_receipts'] == true || json['read_receipts'] == 1,
      lastSeenVisible: json['last_seen_visible'] == true || json['last_seen_visible'] == 1,
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      countryFlag: json['country_flag'] ?? '',
      createdAt: json['created_at'] ?? '',
      verificationStatus: json['verification_status'] ?? 'Verified',
    );
  }

  UserProfile copyWith({
    String? name,
    String? role,
    String? phone,
    String? avatar,
    String? email,
    bool? notificationsEnabled,
    bool? notificationSound,
    bool? notificationVibration,
    bool? security2fa,
    bool? readReceipts,
    bool? lastSeenVisible,
    String? countryCode,
    String? countryName,
    String? countryFlag,
    String? createdAt,
    String? verificationStatus,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration: notificationVibration ?? this.notificationVibration,
      security2fa: security2fa ?? this.security2fa,
      readReceipts: readReceipts ?? this.readReceipts,
      lastSeenVisible: lastSeenVisible ?? this.lastSeenVisible,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      countryFlag: countryFlag ?? this.countryFlag,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}

class BroadcastList {
  final String id;
  final String name;
  final List<String> members;

  BroadcastList({
    required this.id,
    required this.name,
    required this.members,
  });

  factory BroadcastList.fromJson(Map<String, dynamic> json) {
    var memberList = json['members'] as List? ?? [];
    List<String> parsedMembers = memberList.map((m) => m.toString()).toList();
    return BroadcastList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      members: parsedMembers,
    );
  }
}

class BroadcastHistoryItem {
  final int id;
  final String text;
  final String time;
  final String date;
  final int recipientCount;
  final int deliveredCount;
  final bool isFile;
  final String? fileName;
  final String? fileSize;
  final String recipients;

  BroadcastHistoryItem({
    required this.id,
    required this.text,
    required this.time,
    required this.date,
    required this.recipientCount,
    required this.deliveredCount,
    required this.isFile,
    this.fileName,
    this.fileSize,
    required this.recipients,
  });

  factory BroadcastHistoryItem.fromJson(Map<String, dynamic> json) {
    return BroadcastHistoryItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      recipientCount: json['recipient_count'] ?? 0,
      deliveredCount: json['delivered_count'] ?? 0,
      isFile: json['is_file'] == true || json['is_file'] == 1,
      fileName: json['file_name'],
      fileSize: json['file_size'],
      recipients: json['recipients'] ?? '',
    );
  }
}
