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
  final String? managerId;
  final List<Tag> tags;
  final String? email;
  final String? notes;
  final String? countryCode;
  final Message? lastMessage;
  final bool isGroup;
  final bool isChannel;
  final int disappearingTimer;
  final bool isLocked;
  // Phase 1: WhatsApp parity fields
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final bool isBlocked;
  final String? wallpaperUrl;

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
    this.managerId,
    required this.tags,
    this.email,
    this.notes,
    this.countryCode,
    this.lastMessage,
    this.isGroup = false,
    this.isChannel = false,
    this.disappearingTimer = 0,
    this.isLocked = false,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isBlocked = false,
    this.wallpaperUrl,
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
      managerId: json['manager_id'],
      tags: parsedTags,
      email: json['email'],
      notes: json['notes'],
      countryCode: json['country_code'],
      lastMessage: json['last_message'] != null ? Message.fromJson(json['last_message']) : null,
      isGroup: json['is_group'] == 1 || json['is_group'] == true,
      isChannel: json['is_channel'] == 1 || json['is_channel'] == true,
      disappearingTimer: json['disappearing_timer'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isArchived: json['is_archived'] == true,
      isMuted: json['is_muted'] == true,
      isPinned: json['is_pinned'] == true,
      isBlocked: json['is_blocked'] == true,
      wallpaperUrl: json['wallpaper_url'],
    );
  }

  Contact copyWith({
    String? folder,
    List<Tag>? tags,
    int? unreadCount,
    String? assignedStaffId,
    String? managerId,
    String? email,
    String? notes,
    String? countryCode,
    Message? lastMessage,
    bool? isGroup,
    bool? isChannel,
    int? disappearingTimer,
    bool? isLocked,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    bool? isBlocked,
    String? wallpaperUrl,
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
      managerId: managerId ?? this.managerId,
      tags: tags ?? this.tags,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      countryCode: countryCode ?? this.countryCode,
      lastMessage: lastMessage ?? this.lastMessage,
      isGroup: isGroup ?? this.isGroup,
      isChannel: isChannel ?? this.isChannel,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
      isLocked: isLocked ?? this.isLocked,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isBlocked: isBlocked ?? this.isBlocked,
      wallpaperUrl: wallpaperUrl ?? this.wallpaperUrl,
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
  final bool isBroadcast;
  final int? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final bool isEdited;
  final bool isDeleted;
  final bool isPinned;
  final bool isStarred;
  final String? pollId;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? contactCardId;
  final String? contactCardName;
  final String? contactCardPhone;
  // Phase 1: Media & forwarding fields
  final String? mediaType;
  final String? thumbnailUrl;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? forwardedFrom;
  final int forwardCount;
  final bool isViewOnce;
  final bool isViewed;

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
    this.isBroadcast = false,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.isEdited = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.isStarred = false,
    this.pollId,
    this.latitude,
    this.longitude,
    this.locationName,
    this.contactCardId,
    this.contactCardName,
    this.contactCardPhone,
    this.mediaType,
    this.thumbnailUrl,
    this.mediaWidth,
    this.mediaHeight,
    this.forwardedFrom,
    this.forwardCount = 0,
    this.isViewOnce = false,
    this.isViewed = false,
  });

  /// Check if message contains a URL for link preview
  bool get hasLink => text.contains(RegExp(r'https?://|www\.'));

  /// Extract first URL from text
  String? get firstUrl {
    final match = RegExp(r'(https?://[^\s]+|www\.[^\s]+)').firstMatch(text);
    return match?.group(0);
  }

  /// Check if this is a forwarded message
  bool get isForwarded => forwardedFrom != null && forwardedFrom!.isNotEmpty;

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
      isBroadcast: json['is_broadcast'] == 1 || json['is_broadcast'] == true,
      replyToId: json['reply_to_id'],
      replyToText: json['reply_to_text'],
      replyToSender: json['reply_to_sender'],
      isEdited: json['is_edited'] == 1 || json['is_edited'] == true,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      isStarred: json['is_starred'] == 1 || json['is_starred'] == true,
      pollId: json['poll_id'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      locationName: json['location_name'],
      contactCardId: json['contact_card_id'],
      contactCardName: json['contact_card_name'],
      contactCardPhone: json['contact_card_phone'],
      mediaType: json['media_type'],
      thumbnailUrl: json['thumbnail_url'],
      mediaWidth: json['media_width'],
      mediaHeight: json['media_height'],
      forwardedFrom: json['forwarded_from'],
      forwardCount: json['forward_count'] ?? 0,
      isViewOnce: json['is_view_once'] == 1 || json['is_view_once'] == true,
      isViewed: json['is_viewed'] == 1 || json['is_viewed'] == true,
    );
  }
}

class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final String ownerId;
  final int followerCount;
  final bool isVerified;
  final bool isFollowing;

  ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.ownerId,
    required this.followerCount,
    this.isVerified = false,
    this.isFollowing = false,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar'] ?? '',
      ownerId: json['owner_id'] ?? '',
      followerCount: json['follower_count'] ?? 0,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
    );
  }
}

class ChannelPost {
  final String id;
  final String channelId;
  final String text;
  final String? mediaUrl;
  final String createdAt;
  final Map<String, dynamic> reactions;

  ChannelPost({
    required this.id,
    required this.channelId,
    required this.text,
    this.mediaUrl,
    required this.createdAt,
    required this.reactions,
  });

  factory ChannelPost.fromJson(Map<String, dynamic> json) {
    return ChannelPost(
      id: json['id'] ?? '',
      channelId: json['channel_id'] ?? '',
      text: json['text'] ?? '',
      mediaUrl: json['media_url'],
      createdAt: json['created_at'] ?? '',
      reactions: json['reactions'] is Map<String, dynamic> ? json['reactions'] : {},
    );
  }
}

class StatusItem {
  final String id;
  final String contactId;
  final String contentText;
  final String? mediaUrl;
  final String? caption;
  final String createdAt;

  StatusItem({
    required this.id,
    required this.contactId,
    required this.contentText,
    this.mediaUrl,
    this.caption,
    required this.createdAt,
  });

  factory StatusItem.fromJson(Map<String, dynamic> json) {
    return StatusItem(
      id: json['id'] ?? '',
      contactId: json['contact_id'] ?? '',
      contentText: json['content_text'] ?? '',
      mediaUrl: json['media_url'],
      caption: json['caption'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class UserStatus {
  final String contactId;
  final String userName;
  final String userAvatar;
  final List<StatusItem> items;

  UserStatus({
    required this.contactId,
    required this.userName,
    required this.userAvatar,
    required this.items,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<StatusItem> parsedItems = rawItems.map((i) => StatusItem.fromJson(i)).toList();
    return UserStatus(
      contactId: json['contact_id'] ?? '',
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'] ?? '',
      items: parsedItems,
    );
  }
}

class CallLog {
  final int id;
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final String callType; // 'voice' or 'video'
  final String direction; // 'incoming', 'outgoing', 'missed'
  final String timeStr;
  final String? duration;

  CallLog({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    required this.callType,
    required this.direction,
    required this.timeStr,
    this.duration,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'] ?? 0,
      contactId: json['contact_id'] ?? '',
      contactName: json['contact_name'] ?? 'Unknown',
      contactAvatar: json['contact_avatar'] ?? '',
      callType: json['call_type'] ?? 'voice',
      direction: json['direction'] ?? 'incoming',
      timeStr: json['time_str'] ?? '',
      duration: json['duration'],
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
  // Phase 1: About & Privacy fields
  final String about;
  final String profilePhotoPrivacy;
  final String aboutPrivacy;
  final String statusPrivacy;
  final String groupsPrivacy;
  final String lastSeenPrivacy;
  final String onlinePrivacy;

  bool get isCustomer {
    final r = role.toLowerCase().trim();
    return r.contains('customer') || r.contains('client');
  }

  bool get isCeo {
    final r = role.toLowerCase().trim();
    if (r.isEmpty) return false;
    if (r.contains('customer') || r.contains('client') || r.contains('staff') || r.contains('specialist') || r.contains('manager') || r.contains('support')) {
      return false;
    }
    return r == 'ceo' || r == 'founder' || r == 'global ceo' || r == 'chief executive' || r == 'chief executive officer' || r.startsWith('ceo ') || r.endsWith(' ceo');
  }

  bool get isManager {
    if (isCustomer || isCeo) return false;
    final r = role.toLowerCase().trim();
    return r.contains('manager') || r.contains('supervisor') || r.contains('admin');
  }

  bool get isStaff {
    if (isCustomer || isCeo || isManager) return false;
    final r = role.toLowerCase();
    return r.contains('staff') || r.contains('specialist') || r.contains('member') || r.contains('lead') || r.contains('architect') || r.contains('developer') || r.contains('engineer') || r.contains('support');
  }

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
    this.about = 'Hey there! I am using GebTalk',
    this.profilePhotoPrivacy = 'everyone',
    this.aboutPrivacy = 'everyone',
    this.statusPrivacy = 'contacts',
    this.groupsPrivacy = 'everyone',
    this.lastSeenPrivacy = 'everyone',
    this.onlinePrivacy = 'everyone',
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
      about: json['about'] ?? 'Hey there! I am using GebTalk',
      profilePhotoPrivacy: json['profile_photo_privacy'] ?? 'everyone',
      aboutPrivacy: json['about_privacy'] ?? 'everyone',
      statusPrivacy: json['status_privacy'] ?? 'contacts',
      groupsPrivacy: json['groups_privacy'] ?? 'everyone',
      lastSeenPrivacy: json['last_seen_privacy'] ?? 'everyone',
      onlinePrivacy: json['online_privacy'] ?? 'everyone',
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
    String? about,
    String? profilePhotoPrivacy,
    String? aboutPrivacy,
    String? statusPrivacy,
    String? groupsPrivacy,
    String? lastSeenPrivacy,
    String? onlinePrivacy,
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
      about: about ?? this.about,
      profilePhotoPrivacy: profilePhotoPrivacy ?? this.profilePhotoPrivacy,
      aboutPrivacy: aboutPrivacy ?? this.aboutPrivacy,
      statusPrivacy: statusPrivacy ?? this.statusPrivacy,
      groupsPrivacy: groupsPrivacy ?? this.groupsPrivacy,
      lastSeenPrivacy: lastSeenPrivacy ?? this.lastSeenPrivacy,
      onlinePrivacy: onlinePrivacy ?? this.onlinePrivacy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'email': email,
      'notifications_enabled': notificationsEnabled,
      'notification_sound': notificationSound,
      'notification_vibration': notificationVibration,
      'security_2fa': security2fa,
      'read_receipts': readReceipts,
      'last_seen_visible': lastSeenVisible,
      'country_code': countryCode,
      'country_name': countryName,
      'country_flag': countryFlag,
      'created_at': createdAt,
      'verification_status': verificationStatus,
      'about': about,
      'profile_photo_privacy': profilePhotoPrivacy,
      'about_privacy': aboutPrivacy,
      'status_privacy': statusPrivacy,
      'groups_privacy': groupsPrivacy,
      'last_seen_privacy': lastSeenPrivacy,
      'online_privacy': onlinePrivacy,
    };
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

// ========== PHASE 1: New Models ==========

/// Represents a user's typing state in a specific chat
class TypingIndicator {
  final String userId;
  final bool isTyping;

  TypingIndicator({required this.userId, required this.isTyping});

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['user_id'] ?? '',
      isTyping: json['is_typing'] == true,
    );
  }
}

/// Represents a user's online/last-seen presence
class UserPresence {
  final String userId;
  final bool isOnline;
  final String? lastSeen;

  UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] ?? '',
      isOnline: json['is_online'] == true,
      lastSeen: json['last_seen']?.toString(),
    );
  }

  /// Format last seen as human-readable string
  String get lastSeenFormatted {
    if (isOnline) return 'online';
    if (lastSeen == null) return '';
    try {
      final dt = DateTime.parse(lastSeen!);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'last seen just now';
      if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
      if (diff.inDays == 1) return 'last seen yesterday';
      return 'last seen ${diff.inDays}d ago';
    } catch (_) {
      return 'last seen recently';
    }
  }
}

/// Chat preferences (archive/mute/pin/block states)
class ChatPreferences {
  final List<String> archived;
  final Map<String, String?> muted; // contactId -> mutedUntil
  final List<String> pinned;
  final List<String> blocked;
  final Map<String, String> wallpapers; // contactId -> wallpaperUrl

  ChatPreferences({
    this.archived = const [],
    this.muted = const {},
    this.pinned = const [],
    this.blocked = const [],
    this.wallpapers = const {},
  });

  factory ChatPreferences.fromJson(Map<String, dynamic> json) {
    final archivedList = (json['archived'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final mutedMap = <String, String?>{};
    if (json['muted'] is Map) {
      (json['muted'] as Map).forEach((k, v) {
        mutedMap[k.toString()] = v?.toString();
      });
    }
    final pinnedList = (json['pinned'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final blockedList = (json['blocked'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final wallpaperMap = <String, String>{};
    if (json['wallpapers'] is Map) {
      (json['wallpapers'] as Map).forEach((k, v) {
        if (v != null) wallpaperMap[k.toString()] = v.toString();
      });
    }
    return ChatPreferences(
      archived: archivedList,
      muted: mutedMap,
      pinned: pinnedList,
      blocked: blockedList,
      wallpapers: wallpaperMap,
    );
  }
}

/// Read receipt for a single message
class MessageReceipt {
  final String userId;
  final String status;
  final String? timestamp;
  final String? userName;
  final String? userAvatar;

  MessageReceipt({
    required this.userId,
    required this.status,
    this.timestamp,
    this.userName,
    this.userAvatar,
  });

  factory MessageReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReceipt(
      userId: json['user_id'] ?? '',
      status: json['status'] ?? 'delivered',
      timestamp: json['timestamp']?.toString(),
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
    );
  }
}
