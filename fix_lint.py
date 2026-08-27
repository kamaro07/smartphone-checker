with open('checklist_app_flutter/pubspec.yaml', 'r', encoding='utf-8') as f:
    text = f.read()
import re
text = re.sub(r'flutter_lints:\s*\^?6\.\d+\.\d+', 'flutter_lints: ^3.0.0', text)
with open('checklist_app_flutter/pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(text)
