import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';
import '../utils/error_handler.dart';

class ApiService {
  static String? authenticatedPhone;

  static String? _customBaseUrl;

  static String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:5000/api';
      }
      return 'http://127.0.0.1:5000/api';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:5000/api';
        }
      } catch (_) {}
      return 'http://127.0.0.1:5000/api';
    }
  }

  static set baseUrl(String value) {
    _customBaseUrl = value;
  }

  static String resolveUrl(String url) {
    if (!url.startsWith('http')) return url;
    try {
      final currentBase = baseUrl;
      final backendUri = Uri.parse(currentBase);
      final targetUri = Uri.parse(url);
      
      if ((targetUri.host == 'localhost' || targetUri.host == '127.0.0.1') &&
          (backendUri.host != 'localhost' && backendUri.host != '127.0.0.1' && backendUri.host.isNotEmpty)) {
        return targetUri.replace(host: backendUri.host, port: backendUri.port).toString();
      }
    } catch (_) {}
    return url;
  }


  static Future<String?> uploadFile(List<int> bytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
    } catch (e) {
      print('Upload Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> sendOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> verifyOtp(
    String phone,
    String otp, {
    String name = '',
    String countryCode = '',
    String countryName = '',
    String countryFlag = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'name': name,
          'country_code': countryCode,
          'country_name': countryName,
          'country_flag': countryFlag,
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['token'] != null) {
          authenticatedPhone = data['token'];
        }
        return data;
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<List<Folder>> getFolders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/folders'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Folder.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<List<Tag>> getTags() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tags'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Tag.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<Tag?> createTag(String id, String name, String color) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tags'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'name': name, 'color': color}),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        // Find newly created tag in returned list
        for (var item in data) {
          if (item['id'] == id) {
            return Tag.fromJson(item);
          }
        }
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<List<Contact>> getContacts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contacts'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Contact.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<bool> assignContact(String contactId, {String? folder, List<String>? tagIds, String? assignedStaffId}) async {
    try {
      final Map<String, dynamic> body = {};
      if (folder != null) body['folder'] = folder;
      if (tagIds != null) body['tags'] = tagIds;
      if (assignedStaffId != null) body['assigned_staff_id'] = assignedStaffId;

      final response = await http.post(
        Uri.parse('$baseUrl/contacts/$contactId/assign'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
      return false;
    }
  }

  static Future<Contact?> createContact({
    required String name,
    required String phone,
    required String folder,
    String role = '',
    String avatar = '',
    String email = '',
    String notes = '',
    String countryCode = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'folder': folder,
          'role': role,
          'avatar': avatar,
          'email': email,
          'notes': notes,
          'country_code': countryCode,
        }),
      );
      if (response.statusCode == 200) {
        return Contact.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<Contact?> createStaffFolder(String name, String phone, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts/staff'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'role': role,
        }),
      );
      if (response.statusCode == 200) {
        return Contact.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<bool> deleteContact(String contactId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contacts/$contactId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
      return false;
    }
  }

  static Future<List<Message>> getMessages(String contactId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/contacts/$contactId/messages'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Message.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> sendMessage(
    String contactId, {
    String text = '',
    bool isAudio = false,
    String? duration,
    bool isFile = false,
    String? fileName,
    String? fileSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts/$contactId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'is_audio': isAudio,
          'duration': duration,
          'is_file': isFile,
          'file_name': fileName,
          'file_size': fileSize,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<List<String>> reactToMessage(String contactId, int messageId, String emoji) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts/$contactId/messages/$messageId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emoji': emoji}),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> body = jsonDecode(response.body);
        List reactList = body['reactions'] ?? [];
        return reactList.map((r) => r.toString()).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<bool> sendBroadcast(
    List<String> recipientIds,
    String text, {
    bool isFile = false,
    String? fileName,
    String? fileSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/broadcast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipients': recipientIds,
          'text': text,
          'is_file': isFile,
          'file_name': fileName,
          'file_size': fileSize,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
      return false;
    }
  }

  static Future<UserProfile?> getProfile() async {
    try {
      final headers = <String, String>{};
      if (authenticatedPhone != null) {
        headers['Authorization'] = 'Bearer $authenticatedPhone';
        headers['x-user-phone'] = authenticatedPhone!;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<UserProfile?> updateProfile(UserProfile profile) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (authenticatedPhone != null) {
        headers['Authorization'] = 'Bearer $authenticatedPhone';
        headers['x-user-phone'] = authenticatedPhone!;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode({
          'name': profile.name,
          'role': profile.role,
          'phone': profile.phone,
          'avatar': profile.avatar,
          'email': profile.email,
          'notifications_enabled': profile.notificationsEnabled,
          'notification_sound': profile.notificationSound,
          'notification_vibration': profile.notificationVibration,
          'security_2fa': profile.security2fa,
          'read_receipts': profile.readReceipts,
          'last_seen_visible': profile.lastSeenVisible,
          'country_code': profile.countryCode,
          'country_name': profile.countryName,
          'country_flag': profile.countryFlag,
        }),
      );
      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return null;
  }

  static Future<List<BroadcastList>> getBroadcastLists() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/broadcast/lists'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => BroadcastList.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }

  static Future<bool> createBroadcastList(String name, List<String> memberIds, {String? id}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/broadcast/lists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (id != null) 'id': id,
          'name': name,
          'members': memberIds,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
      return false;
    }
  }

  static Future<bool> deleteBroadcastList(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/broadcast/lists/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
      return false;
    }
  }

  static Future<List<BroadcastHistoryItem>> getBroadcastHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/broadcast/history'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => BroadcastHistoryItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('API Error: $e');
      ErrorHandler.showError('Network Error: $e');
    }
    return [];
  }
}
