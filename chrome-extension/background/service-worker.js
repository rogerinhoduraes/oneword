//
//  service-worker.js
//  OneWord Chrome Extension (Manifest V3)
//

// Registra os menus de contexto na instalação
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "oneword-read-selection-app",
    title: "Ler seleção no OneWord App (Foco Total)",
    contexts: ["selection"]
  });

  chrome.contextMenus.create({
    id: "oneword-read-selection-browser",
    title: "Ler seleção no OneWord Web (Painel Lateral)",
    contexts: ["selection"]
  });

  chrome.contextMenus.create({
    id: "oneword-send-page-app",
    title: "Enviar artigo desta página para o OneWord App",
    contexts: ["page"]
  });
});

// Manipula cliques nos menus de contexto
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (!tab || !tab.id) return;

  if (info.menuItemId === "oneword-read-selection-app" && info.selectionText) {
    const text = info.selectionText.trim();
    const title = tab.title || "Seleção da Web";
    const sourceUrl = tab.url || "";
    await sendToNativeApp(tab.id, text, title, sourceUrl);
  } else if (info.menuItemId === "oneword-read-selection-browser" && info.selectionText) {
    const text = info.selectionText.trim();
    const title = tab.title || "Seleção da Web";
    await chrome.storage.local.set({
      currentArticle: {
        text,
        title,
        url: tab.url || "",
        timestamp: Date.now()
      }
    });
    try {
      await chrome.sidePanel.open({ windowId: tab.windowId });
    } catch (err) {
      console.error("[OneWord] Erro ao abrir side panel:", err);
    }
  } else if (info.menuItemId === "oneword-send-page-app") {
    await extractAndSendPage(tab.id, tab.url || "", tab.title || "");
  }
});

// Atalhos de teclado
chrome.commands.onCommand.addListener(async (command) => {
  if (command === "send-page-to-oneword") {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tab && tab.id) {
      await extractAndSendPage(tab.id, tab.url || "", tab.title || "");
    }
  }
});

// Listener para mensagens de páginas internas (popup / sidepanel)
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "openSidePanel") {
    const windowId = sender.tab ? sender.tab.windowId : message.windowId;
    if (windowId) {
      chrome.sidePanel.open({ windowId })
        .then(() => sendResponse({ success: true }))
        .catch((err) => sendResponse({ success: false, error: err.message }));
      return true; // async response
    }
  }

  if (message.action === "sendToApp") {
    const { text, title, url, target } = message;
    if (sender.tab && sender.tab.id) {
      sendToNativeApp(sender.tab.id, text, title, url, target)
        .then((res) => sendResponse(res || { success: true }))
        .catch((err) => sendResponse({ success: false, error: err.message }));
      return true;
    } else {
      // Se enviado do popup, busca aba ativa
      chrome.tabs.query({ active: true, currentWindow: true }).then(([activeTab]) => {
        const tabId = activeTab?.id || null;
        sendToNativeApp(tabId, text, title, url, target)
          .then((res) => sendResponse(res || { success: true }))
          .catch((err) => sendResponse({ success: false, error: err.message }));
      });
      return true;
    }
  }
});

// Função utilitária para extrair artigo da página atual e enviar ao app
async function extractAndSendPage(tabId, url, defaultTitle) {
  try {
    const results = await chrome.scripting.executeScript({
      target: { tabId },
      func: extractCleanPageText
    });

    const extracted = results?.[0]?.result;
    const text = extracted?.text || "";
    const title = extracted?.title || defaultTitle || "Artigo Web";

    if (text.length > 0) {
      await sendToNativeApp(tabId, text, title, url);
    } else {
      // Fallback: envia o URL direto para o OneWord baixar
      const deepLink = `oneword://open?url=${encodeURIComponent(url)}`;
      await triggerDeepLink(tabId, deepLink);
    }
  } catch (err) {
    console.error("[OneWord] Erro ao extrair página:", err);
  }
}

// Envia para o app OneWord nativo via servidor local (127.0.0.1:8765) ou Deep Link (oneword://)
async function sendToNativeApp(tabId, text, title, url) {
  // 1. Tenta envio direto e instantâneo via HTTP Server Local (porta 8765)
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 800);

    const response = await fetch("http://127.0.0.1:8765/read", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        text,
        title,
        url: url || ""
      }),
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    if (response.ok) {
      console.log("[OneWord] Artigo enviado com sucesso via Servidor Local em Tempo Real!");
      return { success: true, method: "localhost" };
    }
  } catch (err) {
    // Servidor local fechado, prossegue para o deep link nativo
    console.log("[OneWord] Servidor local offline, acionando Deep Link oneword://...");
  }

  // 2. Fallback: Deep link oneword:// para abrir o aplicativo nativo
  if (tabId) {
    const truncatedText = text.length > 50000 ? text.slice(0, 50000) : text;
    const deepLink = `oneword://read?text=${encodeURIComponent(truncatedText)}&title=${encodeURIComponent(title)}&url=${encodeURIComponent(url || "")}`;
    await triggerDeepLink(tabId, deepLink);
    return { success: true, method: "deeplink" };
  }

  return { success: false, error: "Não foi possível abrir o app" };
}

async function triggerDeepLink(tabId, link) {
  await chrome.scripting.executeScript({
    target: { tabId },
    func: (url) => {
      // Cria um link temporário e simula clique para não interromper a navegação da página
      const a = document.createElement("a");
      a.href = url;
      a.style.display = "none";
      document.body.appendChild(a);
      a.click();
      setTimeout(() => a.remove(), 1000);
    },
    args: [link]
  });
}

// Função de extração de conteúdo textual limpo injetada na página
function extractCleanPageText() {
  const selection = window.getSelection()?.toString()?.trim();
  if (selection && selection.length > 30) {
    return {
      text: selection,
      title: document.title || "Seleção da Web"
    };
  }

  // Título da página
  const title = (
    document.querySelector("h1")?.innerText ||
    document.querySelector("meta[property='og:title']")?.content ||
    document.title ||
    "Artigo da Web"
  ).trim();

  // Seletores prioritários de artigos
  const selectors = [
    "article",
    "[role='main']",
    "main",
    ".post-content",
    ".article-content",
    ".entry-content",
    "#content"
  ];

  let targetElement = null;
  for (const selector of selectors) {
    const el = document.querySelector(selector);
    if (el && el.innerText && el.innerText.length > 200) {
      targetElement = el;
      break;
    }
  }

  if (!targetElement) {
    targetElement = document.body;
  }

  // Clona o elemento para higienizar sem alterar o DOM visível
  const clone = targetElement.cloneNode(true);
  const elementsToRemove = clone.querySelectorAll(
    "script, style, noscript, nav, header, footer, aside, svg, form, iframe, button, [aria-hidden='true']"
  );
  elementsToRemove.forEach(el => el.remove());

  // Converte quebras em texto legível
  const paragraphs = Array.from(clone.querySelectorAll("p, h1, h2, h3, h4, h5, h6, li, blockquote"))
    .map(p => p.innerText.trim())
    .filter(text => text.length > 0);

  const cleanText = paragraphs.length > 0 ? paragraphs.join("\n\n") : (clone.innerText || "").trim();

  return {
    text: cleanText,
    title: title
  };
}
