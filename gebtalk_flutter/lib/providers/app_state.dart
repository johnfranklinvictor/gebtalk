import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_models.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  bool _authenticated = false;
  String _phoneNumber = '';
  Map<String, dynamic>? _userProfile;
  UserProfile? _currentProfile;
  List<BroadcastList> _broadcastLists = [];
  List<BroadcastHistoryItem> _broadcastHistory = [];

  List<Folder> _folders = [];
  List<Tag> _tags = [];
  List<Contact> _contacts = [];
  List<Message> _activeChatHistory = [];
  
  String? _activeContactId;
  String _activeFolderId = 'all';
  String? _selectedTagId;
  String _searchQuery = '';
  bool _isLoading = false;

  bool _isAdmin = true;
  String _currentStaffId = 'sarah';
  Timer? _contactsTimer;

  // Getters
  bool get authenticated => _authenticated;
  String get phoneNumber => _phoneNumber;
  Map<String, dynamic>? get userProfile => _userProfile;
  UserProfile? get currentProfile => _currentProfile;
  List<BroadcastList> get broadcastLists => _broadcastLists;
  List<BroadcastHistoryItem> get broadcastHistory => _broadcastHistory;

  List<Folder> get folders => _folders;
  List<Tag> get tags => _tags;
  List<Contact> get contacts => _contacts;
  List<Message> get activeChatHistory => _activeChatHistory;
  
  String? get activeContactId => _activeContactId;
  String get activeFolderId => _activeFolderId;
  String? get selectedTagId => _selectedTagId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String get currentStaffId => _currentStaffId;

  // Filtered contacts based on active folder, tag, search query, and permissions
  List<Contact> get filteredContacts {
    return _contacts.where((contact) {
      // 1. Permissions check for customers
      if (!_isAdmin && contact.folder == 'customers') {
        if (contact.assignedStaffId != _currentStaffId) return false;
      }

      // 2. Permissions check for staff folders (when folder list is filtered to 'staff')
      if (!_isAdmin && contact.folder == 'staff') {
        if (contact.id != _currentStaffId) return false;
      }

      // 3. Folder filter
      if (_activeFolderId != 'all') {
        if (contact.folder != _activeFolderId) return false;
      }
      
      // 4. Tag filter
      if (_selectedTagId != null) {
        bool hasTag = contact.tags.any((t) => t.id == _selectedTagId);
        if (!hasTag) return false;
      }
      
      // 5. Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatches = contact.name.toLowerCase().contains(query);
        final roleMatches = contact.role.toLowerCase().contains(query);
        if (!nameMatches && !roleMatches) return false;
      }
      
      return true;
    }).toList();
  }

  void toggleAdminMode() {
    _isAdmin = !_isAdmin;
    notifyListeners();
  }

  Contact? get activeContact {
    if (_activeContactId == null) return null;
    return _contacts.firstWhere((c) => c.id == _activeContactId, orElse: () => _contacts[0]);
  }

  // Setters & Actions
  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    notifyListeners();
  }

  Future<bool> verifyOtpCode(String otp, {String name = '', String countryCode = '', String countryName = '', String countryFlag = ''}) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.verifyOtp(
      _phoneNumber,
      otp,
      name: name,
      countryCode: countryCode,
      countryName: countryName,
      countryFlag: countryFlag,
    );
    _isLoading = false;

    if (response != null) {
      _authenticated = true;
      _userProfile = response['user'];
      notifyListeners();
      await fetchInitialData();
      startContactsPolling();
      return true;
    }
    notifyListeners();
    return false;
  }

  void startContactsPolling() {
    _contactsTimer?.cancel();
    _contactsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_authenticated) {
        refreshContacts();
      }
    });
  }

  void stopContactsPolling() {
    _contactsTimer?.cancel();
    _contactsTimer = null;
  }

  @override
  void dispose() {
    stopContactsPolling();
    super.dispose();
  }

  void logout() {
    _authenticated = false;
    _phoneNumber = '';
    _userProfile = null;
    ApiService.authenticatedPhone = null;
    stopContactsPolling();
    notifyListeners();
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();

    _folders = await ApiService.getFolders();
    _tags = await ApiService.getTags();
    _contacts = await ApiService.getContacts();
    await fetchProfile();
    await fetchBroadcastLists();
    await fetchBroadcastHistory();
    
    _isLoading = false;
    notifyListeners();
    startContactsPolling();
  }

  void setActiveFolder(String folderId) {
    _activeFolderId = folderId;
    notifyListeners();
  }

  void toggleTagFilter(String tagId) {
    if (_selectedTagId == tagId) {
      _selectedTagId = null;
    } else {
      _selectedTagId = tagId;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> selectContact(String contactId) async {
    _activeContactId = contactId;
    _activeChatHistory = [];
    notifyListeners();

    // Fetch messages from api
    _activeChatHistory = await ApiService.getMessages(contactId);
    
    // Clear local unread counts in contact list
    int index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      _contacts[index] = _contacts[index].copyWith(unreadCount: 0);
    }
    
    notifyListeners();
  }

  void closeConversation() {
    _activeContactId = null;
    _activeChatHistory = [];
    notifyListeners();
    refreshContacts(); // Refresh list to get any new updates
  }

  Future<void> refreshContacts() async {
    _contacts = await ApiService.getContacts();
    notifyListeners();
  }

  Future<bool> sendMessage(String text, {bool isAudio = false, String? duration, bool isFile = false, String? fileName, String? fileSize}) async {
    if (_activeContactId == null) return false;
    final contactId = _activeContactId!;

    final response = await ApiService.sendMessage(
      contactId,
      text: text,
      isAudio: isAudio,
      duration: duration,
      isFile: isFile,
      fileName: fileName,
      fileSize: fileSize,
    );

    if (response != null && response['status'] == 'success') {
      // Append user message
      final userMsg = Message.fromJson(response['user_message']);
      _activeChatHistory.add(userMsg);

      // Append bot message if any
      if (response['bot_message'] != null) {
        final botMsg = Message.fromJson(response['bot_message']);
        _activeChatHistory.add(botMsg);
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> pollMessages() async {
    if (_activeContactId == null) return;
    final contactId = _activeContactId!;
    try {
      final newHistory = await ApiService.getMessages(contactId);
      
      bool isDifferent = newHistory.length != _activeChatHistory.length;
      if (!isDifferent && newHistory.isNotEmpty && _activeChatHistory.isNotEmpty) {
        if (newHistory.last.id != _activeChatHistory.last.id ||
            newHistory.last.reactions.length != _activeChatHistory.last.reactions.length) {
          isDifferent = true;
        } else {
          for (int i = 0; i < newHistory.length; i++) {
            if (newHistory[i].text != _activeChatHistory[i].text ||
                newHistory[i].reactions.length != _activeChatHistory[i].reactions.length) {
              isDifferent = true;
              break;
            }
          }
        }
      }
      
      if (isDifferent) {
        _activeChatHistory = newHistory;
        notifyListeners();
      }
    } catch (e) {
      print('Polling Error: $e');
    }
  }

  Future<void> reactToMessage(int messageId, String emoji) async {
    if (_activeContactId == null) return;
    final contactId = _activeContactId!;

    final newReactions = await ApiService.reactToMessage(contactId, messageId, emoji);
    
    int index = _activeChatHistory.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final old = _activeChatHistory[index];
      _activeChatHistory[index] = Message(
        id: old.id,
        contactId: old.contactId,
        text: old.text,
        isUser: old.isUser,
        time: old.time,
        isAudio: old.isAudio,
        duration: old.duration,
        isFile: old.isFile,
        fileName: old.fileName,
        fileSize: old.fileSize,
        reactions: newReactions,
        status: old.status,
      );
      notifyListeners();
    }
  }

  Future<bool> updateContactAssignments(String contactId, String folder, List<String> tagIds) async {
    final success = await ApiService.assignContact(contactId, folder: folder, tagIds: tagIds);
    if (success) {
      // Update local state
      List<Tag> assignedTags = _tags.where((t) => tagIds.contains(t.id)).toList();
      int index = _contacts.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(folder: folder, tags: assignedTags);
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> moveCustomerToStaff(String customerId, String staffId) async {
    final success = await ApiService.assignContact(customerId, assignedStaffId: staffId);
    if (success) {
      int index = _contacts.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(assignedStaffId: staffId);
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> removeCustomerFromStaff(String customerId) async {
    final success = await ApiService.assignContact(customerId, assignedStaffId: "");
    if (success) {
      int index = _contacts.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(assignedStaffId: "");
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> addContact({
    required String name,
    required String phone,
    required String folder,
    String role = '',
    String avatar = '',
    String email = '',
    String notes = '',
    String countryCode = '',
  }) async {
    _isLoading = true;
    notifyListeners();
    final newContact = await ApiService.createContact(
      name: name,
      phone: phone,
      folder: folder,
      role: role,
      avatar: avatar,
      email: email,
      notes: notes,
      countryCode: countryCode,
    );
    _isLoading = false;
    if (newContact != null) {
      _contacts.add(newContact);
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<bool> addStaffFolder(String name, String phone, String role) async {
    return addContact(
      name: name,
      phone: phone,
      folder: 'staff',
      role: role,
    );
  }

  Future<bool> deleteStaffFolder(String staffId) async {
    final success = await ApiService.deleteContact(staffId);
    if (success) {
      _contacts.removeWhere((c) => c.id == staffId);
      for (int i = 0; i < _contacts.length; i++) {
        if (_contacts[i].assignedStaffId == staffId) {
          _contacts[i] = _contacts[i].copyWith(assignedStaffId: "");
        }
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> createAndAddTag(String name, String color) async {
    String id = name.toLowerCase().replaceAll(' ', '_');
    final newTag = await ApiService.createTag(id, name, color);
    if (newTag != null) {
      _tags.add(newTag);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> fetchProfile() async {
    final profile = await ApiService.getProfile();
    if (profile != null) {
      _currentProfile = profile;
      _userProfile = {
        'name': profile.name,
        'role': profile.role,
        'avatar': profile.avatar,
        'email': profile.email,
        'phone': profile.phone,
      };
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();
    final updated = await ApiService.updateProfile(profile);
    _isLoading = false;
    if (updated != null) {
      _currentProfile = updated;
      _userProfile = {
        'name': updated.name,
        'role': updated.role,
        'avatar': updated.avatar,
        'email': updated.email,
        'phone': updated.phone,
      };
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> fetchBroadcastLists() async {
    _broadcastLists = await ApiService.getBroadcastLists();
    notifyListeners();
  }

  Future<bool> createBroadcastList(String name, List<String> memberIds, {String? id}) async {
    _isLoading = true;
    notifyListeners();
    final success = await ApiService.createBroadcastList(name, memberIds, id: id);
    _isLoading = false;
    if (success) {
      await fetchBroadcastLists();
    }
    notifyListeners();
    return success;
  }

  Future<bool> deleteBroadcastList(String id) async {
    _isLoading = true;
    notifyListeners();
    final success = await ApiService.deleteBroadcastList(id);
    _isLoading = false;
    if (success) {
      await fetchBroadcastLists();
    }
    notifyListeners();
    return success;
  }

  Future<void> fetchBroadcastHistory() async {
    _broadcastHistory = await ApiService.getBroadcastHistory();
    notifyListeners();
  }

  Future<bool> sendBroadcastMessage(
    List<String> recipientIds,
    String text, {
    bool isFile = false,
    String? fileName,
    String? fileSize,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await ApiService.sendBroadcast(
      recipientIds,
      text,
      isFile: isFile,
      fileName: fileName,
      fileSize: fileSize,
    );
    _isLoading = false;
    notifyListeners();

    if (success) {
      await refreshContacts();
      await fetchBroadcastHistory();
    }
    return success;
  }
}
