with open('checklist_app_flutter/android/settings.gradle.kts', 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('version \"9.0.1\"', 'version \"8.7.3\"')
with open('checklist_app_flutter/android/settings.gradle.kts', 'w', encoding='utf-8') as f:
    f.write(text)
