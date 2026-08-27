(Get-Content checklist_app_flutter/pubspec.yaml) -replace 'light_sensor: \^3\.0\.2', 'light: ^3.0.0' | Set-Content checklist_app_flutter/pubspec.yaml
