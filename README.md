<div align="center">

# OneWord

**Leitura dinâmica RSVP para iPhone, iPad e Mac.**
Uma palavra por vez, no ritmo do seu olhar.

![Plataformas](https://img.shields.io/badge/plataformas-iOS%2017%2B%20%7C%20macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
[![CI](https://github.com/rogerinhoduraes/oneword/actions/workflows/ci.yml/badge.svg)](https://github.com/rogerinhoduraes/oneword/actions/workflows/ci.yml)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-green.svg)](LICENSE)

</div>

## O que é

OneWord apresenta o texto palavra por palavra (técnica **RSVP**), alinhando cada palavra ao ponto ótimo de reconhecimento (**ORP**) para você ler mais rápido e com menos movimento ocular. O app é gratuito, suportado por anúncios, e funciona com seus próprios livros e documentos.

## Funcionalidades

- **Leitor RSVP** com guia ORP, controle de velocidade e ritmo adaptativo.
- **Importação** de EPUB, PDF, artigos da web e texto escaneado (OCR com Vision).
- **Leitura bionic** e narração sincronizada (`AVSpeechSynthesizer`).
- **Processamento local (NaturalLanguage):** resumos, flashcards e quizzes dinâmicos, sem enviar o texto para servidores.
- **Tradução** de livros e definição de palavras.
- **Estatísticas e hábitos:** WPM, sequência de leitura, conquistas e benchmark de velocidade.
- **Ecossistema Apple:** Live Activities, Dynamic Island, App Intents (Siri e Atalhos), Apple Pencil, háptica e eye-tracking.
- **Idiomas:** português, inglês e espanhol.
- **Extensão para Chrome** e **servidor web** que enviam artigos ao app via `oneword://`.

## Stack

| Camada | Tecnologia |
|---|---|
| UI | SwiftUI, `@Observable` |
| Persistência | SwiftData |
| Arquitetura | MVVM, serviços desacoplados por protocolos |
| Visão computacional | Vision, VisionKit |
| Anúncios | Google Mobile Ads (AdMob) + UMP |
| Extensão web | Chrome Manifest V3 |
| Servidor | Node.js (`oneword-cloud`) |

## Estrutura

```
OneWord/Sources/OneWord/      Núcleo do app (Models, Views, ViewModels, Services)
OneWord/Sources/OneWordApp/   Executável para macOS
OneWord.xcodeproj             Projeto Xcode (iOS/macOS)
Package.swift                 Pacote SwiftPM
chrome-extension/             Extensão Chrome + conector RSVP
oneword-cloud/                Servidor web e leitor RSVP no navegador
docs/ e *.md                  Documentação técnica
scripts/                      Utilitários (ícones, projeto)
```

## Como compilar

Requisitos: macOS 14+, Xcode 15+.

```bash
git clone https://github.com/rogerinhoduraes/oneword.git
cd oneword
swift build          # núcleo + executável macOS
open OneWord.xcodeproj   # para rodar no simulador iOS
```

> **Anúncios:** as builds de **Debug** usam IDs de teste do AdMob. Os IDs de produção em `AdConfig.swift` e `Info.plist` pertencem ao app publicado. Se for publicar um fork, substitua por IDs seus.

## Documentação técnica

- [Referência de APIs iOS](IOS_DEVELOPER_REFERENCE.md)
- [Otimização de energia e bateria no iPhone](IPHONE_BATTERY_AND_POWER_OPTIMIZATION.md)
- [Mecanismos físicos do hardware Apple](docs/APPLE_HARDWARE_PHYSICAL_MECHANISMS.md)
- [Extensão Chrome](chrome-extension/README.md)

## Contribuindo

Contribuições são bem-vindas. Leia o [CONTRIBUTING.md](CONTRIBUTING.md) e o [Código de Conduta](CODE_OF_CONDUCT.md). Para vulnerabilidades, veja o [SECURITY.md](SECURITY.md).

## Licença

[MIT](LICENSE) © 2026 Rogerio Duraes
