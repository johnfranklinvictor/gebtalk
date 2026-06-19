import 'dart:io';

void main() {
  final file = File('lib/screens/chat_list_screen.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    "appState.addContact(newStaff);",
    "appState.addStaffFolder(staffName, '', 'Staff');"
  );
  
  content = content.replaceAll(
    "appState.removeContact(staff.id);",
    "appState.deleteStaffFolder(staff.id);"
  );
  
  content = content.replaceAll(
    "appState.assignCustomerToStaff(customer.id, null);",
    "appState.removeCustomerFromStaff(customer.id);"
  );

  file.writeAsStringSync(content);
  print('Fixed AppState methods in chat_list_screen.dart');
}
