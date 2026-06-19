import 'dart:io';

void main() {
  final file = File('lib/widgets/interactive_customer_card.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    "widget.contact.priority == 'high'",
    "widget.contact.tags.any((t) => t.name.toLowerCase() == 'high priority' || t.name.toLowerCase() == 'vip')"
  );
  
  content = content.replaceAll(
    "widget.contact.tags.first.toUpperCase()",
    "widget.contact.tags.first.name.toUpperCase()"
  );

  file.writeAsStringSync(content);
  print('Fixed interactive_customer_card.dart');
}
