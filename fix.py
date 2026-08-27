with open('checklist_app_flutter/pubspec.yaml', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('sdk: ^3.12.2', 'sdk: \">=3.3.0 <4.0.0\"')
with open('checklist_app_flutter/pubspec.yaml', 'w', encoding='utf-8') as f:
    f.write(text)
