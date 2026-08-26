# APK_OVERVIEW.md

## Tecnologias Utilizadas
- **Flutter 3** e **Dart 3** – framework e linguagem principal.
- Plugins nativos:
  - `local_auth` – impressão digital/biometria.
  - `proximity_sensor` – sensor de proximidade.
  - `light_sensor` – sensor de luz ambiente.
  - `flutter_sound` – gravação de áudio (10 s).
  - `flutter_nfc_kit` – leitura de tags NFC.

## Arquitetura do APK
- **classes.dex** – bytecode compilado do Dart.
- **lib/armeabi‑v7a/*.so** – bibliotecas nativas dos plugins.
- **resources.arsc** – recursos Android (strings, layouts).
- **assets/** – imagens, fontes e arquivos de tradução.
- **META-INF/** – assinatura (presente apenas em builds de release).

## Como a IA pode modificar o app futuramente
1. **Adicionar novos serviços** – criar arquivos em `lib/services/` e atualizar `pubspec.yaml`.
2. **Novas telas UI** – implementar em `lib/screens/` e fazer navegação via `Navigator`.
3. **Permissões Android** – editar `android/app/src/main/AndroidManifest.xml` para novos recursos nativos.
4. **Recompilar** – disparar o workflow `build_apk.yml` via API do GitHub.
5. **Gerar QR‑code** – executar `scripts/generate_qr_code.py` apontando ao novo release.

## Build futuro
- Para produção, usar `flutter build apk --release` e configurar keystore em `android/app/`.
- Ajustar o workflow para usar a flag `--release` e incluir etapas de assinatura.
