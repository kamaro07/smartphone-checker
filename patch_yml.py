with open('.github/workflows/build-apk.yml', 'r') as f:
    content = f.read()

patch_step = """
      - name: Patch light plugin
        run: |
          python -c "
          import os
          path = '/home/runner/.pub-cache/hosted/pub.dev/light-3.0.1/android/build.gradle'
          if os.path.exists(path):
              with open(path, 'r') as f:
                  c = f.read()
              if 'namespace' not in c:
                  c = c.replace('android {', 'android {\\n    namespace \\\"com.github.bruno128.light\\\"\\n')
                  with open(path, 'w') as f:
                      f.write(c)
              print('Patched successfully')
          "
"""
# Insert after 'flutter pub get'
content = content.replace('working-directory: checklist_app_flutter\n', 'working-directory: checklist_app_flutter\n' + patch_step)

with open('.github/workflows/build-apk.yml', 'w') as f:
    f.write(content)
