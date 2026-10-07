# Contribuindo com o OneWord

Obrigado pelo interesse! Este guia explica como colaborar.

## Antes de começar

- Procure nas [issues](https://github.com/rogerinhoduraes/oneword/issues) se o assunto já existe.
- Para mudanças grandes, abra uma issue antes para alinharmos a abordagem.

## Ambiente

Requisitos: macOS 14+, Xcode 15+.

```bash
git clone https://github.com/<seu-usuario>/oneword.git
cd oneword
swift build
```

## Fluxo

1. Faça um fork e crie uma branch a partir de `master`: `feat/nome`, `fix/nome` ou `docs/nome`.
2. Faça mudanças pequenas e focadas. Não refatore código não relacionado.
3. Garanta que `swift build` passa.
4. Use commits no padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/) (`feat:`, `fix:`, `docs:`, `chore:`).
5. Abra um Pull Request preenchendo o template.

## Estilo

- Siga o estilo do código vizinho (nomes, comentários, idioma).
- Textos visíveis ao usuário vão em `Localizable.xcstrings` (pt, en, es).
- Não commite chaves, certificados nem arquivos de build.

## Sobre anúncios

Não altere os IDs de produção do AdMob em PRs.
