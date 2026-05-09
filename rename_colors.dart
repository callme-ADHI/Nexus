import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var newContent = content
          .replaceAll('violetPrimary', 'accentPrimary')
          .replaceAll('violetLight', 'accentSecondary')
          .replaceAll('violetGlow', 'accentGlow');
      if (content != newContent) {
        file.writeAsStringSync(newContent);
        print('Updated \${file.path}');
      }
    }
  }
}
