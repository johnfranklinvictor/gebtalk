import 'dart:io';

void main() {
  final file = File('lib/screens/chat_list_screen.dart');
  String content = file.readAsStringSync();
  
  final methods = '''
  void _showCreateStaffDialog(BuildContext context, AppState appState) {
    String staffName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create Staff Vault', style: TextStyle(color: Colors.white)),
          content: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Enter Name", hintStyle: TextStyle(color: AppColors.textMuted)),
            onChanged: (val) => staffName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (staffName.isNotEmpty) {
                  final newStaff = Contact(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: staffName,
                    phone: '',
                    role: 'Staff',
                    avatar: '',
                    status: 'online',
                    folder: 'staff',
                    unreadCount: 0,
                    tags: [],
                  );
                  appState.addContact(newStaff);
                }
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteStaffDialog(BuildContext context, AppState appState, Contact staff) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete Vault', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this Command Vault?', style: TextStyle(color: AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () {
                appState.removeContact(staff.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveCustomerDialog(BuildContext context, AppState appState, Contact customer) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Remove Target', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to remove this target from the vault?', style: TextStyle(color: AppColors.textLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () {
                appState.assignCustomerToStaff(customer.id, null);
                Navigator.pop(context);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showReassignDialog(BuildContext context, AppState appState, Contact customer) {
    // Basic reassign stub
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reassign feature not fully implemented in Gamified mode.')));
  }
''';

  int startIdx = content.indexOf('void _showCreateStaffDialog');
  if (startIdx != -1) {
    int endIdx = content.lastIndexOf('}') - 1; // before the last brace of class
    content = content.substring(0, startIdx) + methods + "}\n";
    file.writeAsStringSync(content);
    print('Replaced missing dialog methods with logic');
  } else {
    print('Could not find existing stubs');
  }
}
