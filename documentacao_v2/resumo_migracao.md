# Documentação - Smartphone Checker V2 (Migração para Flutter)

## 1. Histórico e Motivação
A versão anterior do aplicativo havia sido construída em React Native e estava apresentando erros de JSI e problemas de vinculação nativa (`UnsatisfiedLinkError`) ao rodar em produção. Para alcançar uma performance muito superior e garantir total acesso ao hardware do celular (como exigido em ferramentas de diagnóstico), decidimos **reescrever o aplicativo inteiro de forma nativa utilizando o motor C++ do Flutter (Dart)**.

## 2. Novas Funcionalidades (Versão V2)

1. **Alta Performance (Compilação Nativa):** 
   - A interface agora roda fluída e instantânea.
   - O aplicativo final (`app-release.apk`) funciona independente e tem melhor compatibilidade.

2. **Suporte a Múltiplos Idiomas:**
   - Adicionada biblioteca `easy_localization`.
   - Suporte incluído e configurado para: Português (pt), Inglês (en) e Espanhol (es).
   - O usuário pode alterar o idioma em tempo real clicando no ícone de "globo" no canto superior direito.

3. **Persistência de Dados Inteligente (Local Storage):**
   - O IP do *Desktop Controller* (o servidor Node.js que recebe os dados via Wi-Fi) agora é salvo na memória persistente do celular.
   - Não é mais necessário redigitar o IP todas as vezes que o aplicativo é aberto.

4. **Teste de Touch Interativo (Grid 15x8):**
   - Substituímos o teste abstrato anterior por um **Teste de Tela Interativo de Pintura**.
   - O usuário deve passar o dedo pela tela e pintar 95% do display (marcados em verde) para provar que o touch não possui pontos mortos (dead zones).
   - A tela é automaticamente aprovada e fechada quando a condição é atendida.

5. **Extração Automática de Hardware:**
   - Implementado o uso do plugin `device_info_plus`.
   - O aplicativo detecta e mostra automaticamente a **Marca** e o **Modelo** do dispositivo rodando os testes antes mesmo de começar.

## 3. Estrutura do Novo Projeto

O novo código-fonte em Flutter encontra-se na pasta `checklist_app_flutter`. 
A estrutura de arquivos principal ficou assim:

- `lib/main.dart`: Arquivo mestre que inicia as rotas e injeta o provedor de traduções.
- `lib/screens/home_screen.dart`: Tela principal onde ocorre o Scanner de Código de Barras (IMEI), seleção de idioma, entrada do IP e exibição da detecção do celular.
- `lib/screens/test_screen.dart`: A tela que concentra a lista de testes de hardware (Tela, Vibração, Som, Wi-Fi, USB) e executa o ping e auto-teste das conexões.
- `lib/screens/result_screen.dart`: A tela final que totaliza testes "Aprovados", "Reprovados" e "Não Testados", responsável por emitir a requisição final para o Desktop Controller gerar o relatório PDF.
- `assets/langs/`: Pasta contendo os arquivos `.json` com o dicionário de cada idioma.

## 4. Integração Contínua e Versionamento (GitHub)
- O projeto foi versionado com o Git.
- Todos os códigos, assets antigos, o backend Node.js antigo e o novo frontend Flutter foram compactados e enviados em uma ramificação única (`main`).
- O APK final compilado encontra-se atualizado direto no repositório do Github. O link gerado para acesso externo, para download direto para clientes/testadores é: `https://raw.githubusercontent.com/kamaro07/smartphone-checker/main/checklist-server/public/app-release.apk`

---
*Documentação gerada pelo Google Antigravity Agent em parceria com o Usuário.*
