class EmailAttachment {
  final String name;
  final String size;
  final String type;
  final String url;

  EmailAttachment({
    required this.name,
    required this.size,
    required this.type,
    required this.url,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      name: json['name'] ?? 'Attachment',
      size: json['size'] ?? '',
      type: json['type'] ?? 'file',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'size': size,
    'type': type,
    'url': url,
  };
}

class EmailMessage {
  final String id;
  final String folder;
  final String fromAddress;
  final String fromName;
  final String toAddresses;
  final String subject;
  final String bodyText;
  final String bodyHtml;
  final bool hasAttachments;
  final List<EmailAttachment> attachments;
  bool isRead;
  bool isStarred;
  final String? linkedContactId;
  final String receivedAt;

  EmailMessage({
    required this.id,
    required this.folder,
    required this.fromAddress,
    required this.fromName,
    required this.toAddresses,
    required this.subject,
    required this.bodyText,
    required this.bodyHtml,
    required this.hasAttachments,
    required this.attachments,
    required this.isRead,
    required this.isStarred,
    this.linkedContactId,
    required this.receivedAt,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    List<EmailAttachment> attList = [];
    if (json['attachments'] != null) {
      attList = (json['attachments'] as List)
          .map((a) => EmailAttachment.fromJson(Map<String, dynamic>.from(a)))
          .toList();
    }

    return EmailMessage(
      id: json['id'] ?? '',
      folder: json['folder'] ?? 'inbox',
      fromAddress: json['from_address'] ?? '',
      fromName: json['from_name'] ?? json['from_address'] ?? 'Unknown',
      toAddresses: json['to_addresses'] ?? '',
      subject: json['subject'] ?? '(No Subject)',
      bodyText: json['body_text'] ?? '',
      bodyHtml: json['body_html'] ?? '',
      hasAttachments: json['has_attachments'] == true,
      attachments: attList,
      isRead: json['is_read'] == true,
      isStarred: json['is_starred'] == true,
      linkedContactId: json['linked_contact_id'],
      receivedAt: json['received_at'] ?? '',
    );
  }
}

class ContactRequest {
  final int id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderEmail;
  final String senderAvatar;
  final String senderUsername;
  final String status;
  final String message;
  final String createdAt;

  ContactRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderEmail,
    required this.senderAvatar,
    required this.senderUsername,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory ContactRequest.fromJson(Map<String, dynamic> json) {
    return ContactRequest(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      senderName: json['sender_name'] ?? 'User',
      senderEmail: json['sender_email'] ?? '',
      senderAvatar: json['sender_avatar'] ?? '',
      senderUsername: json['sender_username'] ?? '',
      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class DirectoryUser {
  final String id;
  final String email;
  final String username;
  final String name;
  final String avatar;
  final String role;
  final String statusText;
  final String about;
  final String presence;
  final bool isVerified;
  final bool isConnected;

  DirectoryUser({
    required this.id,
    required this.email,
    required this.username,
    required this.name,
    required this.avatar,
    required this.role,
    required this.statusText,
    required this.about,
    required this.presence,
    required this.isVerified,
    required this.isConnected,
  });

  factory DirectoryUser.fromJson(Map<String, dynamic> json) {
    return DirectoryUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      role: json['role'] ?? 'User',
      statusText: json['status_text'] ?? 'Available',
      about: json['about'] ?? 'Using GEBTALK',
      presence: json['presence'] ?? 'online',
      isVerified: json['is_verified'] == true,
      isConnected: json['is_connected'] == true,
    );
  }
}
