# 🌐 OneWord - Extensão para Google Chrome & Conector do App

Extensão oficial do **OneWord** para o Google Chrome (Manifest V3). Permite acelerar a leitura de qualquer artigo ou texto na web utilizando a técnica neurocognitiva **RSVP (Rapid Serial Visual Presentation)** com guias **ORP (Optimal Recognition Point)** diretamente no navegador, ou enviar o conteúdo com um clique para o aplicativo nativo **OneWord (macOS/iOS)**.

---

## ✨ Recursos

1. **Conector com App OneWord (Deep Link `oneword://`)**:
   - Botão **"Abrir no OneWord App (macOS)"** transfere instantaneamente o artigo higienizado para a biblioteca e inicia o leitor nativo.
   - Suporte ao protocolo `oneword://read?text=...&title=...&url=...` e `oneword://open?url=...`.
2. **Leitor RSVP Integrado no Chrome**:
   - **Popup Rápido**: Leitura foveal instantânea ao clicar no ícone da extensão.
   - **Side Panel (Painel Lateral)**: Leitura em tela dividida lado a lado com sua navegação.
   - Destaque foveal central **ORP em vermelho** (`#EF4444`) que elimina movimentos sacádicos dos olhos.
   - Ritmo inteligente (*Smart Pacing*): pausas dinâmicas em pontuações (. ? ! , ; :) e palavras longas.
   - Controle de velocidade ajustável de **150 a 900+ WPM**.
   - Três temas refinados: **Escuro (Dark)**, **Claro (Light)** e **Sépia**.
3. **Menu de Contexto (Botão Direito)**:
   - *"Ler seleção no OneWord App (Foco Total)"*: Envia o trecho marcado para o app macOS.
   - *"Ler seleção no OneWord Web (Painel Lateral)"*: Abre o painel lateral com o texto selecionado.
   - *"Enviar artigo desta página para o OneWord App"*: Extrai o artigo da página e despacha para o app nativo.
4. **Atalhos de Teclado**:
   - `Alt + Shift + O`: Abre o leitor OneWord no navegador.
   - `Alt + Shift + W`: Envia a página atual diretamente para o OneWord App.
   - `Espaço`: Iniciar / Pausar leitura.
   - `Seta Esquerda` / `Seta Direita`: Voltar / Avançar 10 palavras.
   - `Seta Cima` / `Seta Baixo`: Aumentar / Diminuir velocidade (+25 / -25 WPM).

---

## 🚀 Como Instalar no Google Chrome

1. Abra o Google Chrome e acesse a página de extensões digitando na barra de endereços:
   ```
   chrome://extensions/
   ```
2. Ative a chave **"Modo do desenvolvedor"** (*Developer mode*) no canto superior direito.
3. Clique no botão **"Carregar sem compactação"** (*Load unpacked*).
4. Selecione a pasta deste projeto:
   ```
   /Users/rogerioduraes/Documents/dev/OneWord/chrome-extension
   ```
5. A extensão **OneWord - Leitor RSVP & Conector** aparecerá pronta para uso!
6. Fixe o ícone do OneWord na barra de ferramentas do Chrome para acesso imediato.

---

## 📱 Integração e Vínculo com o App Nativo OneWord

A extensão se conecta com o OneWord através de **dois canais inteligentes**:

### 1. 🟢 Conexão em Tempo Real (Servidor Local - `http://127.0.0.1:8765`)
- Quando o app OneWord está aberto no Mac ou iPhone/iPad, ele ativa um servidor local assíncrono e ultraleve (`OneWordLocalServer`) via `Network.framework`.
- A extensão detecta o app automaticamente (indicador **🟢 OneWord App: Conectado**).
- O envio do artigo é **instantâneo, silencioso e sem nenhuma caixa de diálogo** do sistema operacional.
- O app OneWord recebe o texto, processa com o `TextParser`, salva no SwiftData e projeta a tela do leitor RSVP na hora.

### 2. 🚀 Fallback Automático via Deep Link (`oneword://`)
- Caso o app OneWord esteja fechado, a extensão despacha o comando via esquema de URL registrado no macOS (`oneword://read` ou `oneword://open`).
- O sistema operacional inicializa o aplicativo com o conteúdo pré-carregado.

---

## 🧪 Como Testar a Conexão Agora Mesmo

1. **Abra o App OneWord**:
   - No Xcode, clique em **Run** (ou `Cmd + R`) com o target `OneWord`.
   - Você verá a mensagem no console do Xcode: `[OneWord LocalServer] Servidor ativo em http://127.0.0.1:8765`.
2. **Abra o Chrome**:
   - Clique no ícone do OneWord. Você notará o badge verde: `🟢 OneWord App: Conectado (Tempo Real)`.
3. **Leia e Transfira**:
   - Em qualquer artigo ou notícia na web, clique em **"Abrir no OneWord App (macOS)"** ou selecione um parágrafo com o botão direito -> *"Ler seleção no OneWord App"*.
   - O app OneWord abre o leitor RSVP imediatamente com o texto transferido!
