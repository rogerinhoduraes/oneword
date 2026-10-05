//
//  popup.js
//  OneWord Chrome Extension Popup Controller
//

import { RSVPEngine } from "../shared/rsvp-engine.js";
import { extractPDFTextFromFile, extractPDFTextFromUrl } from "../shared/pdf-extractor.js";

// Elementos DOM
const dom = {
  sourceTitle: document.getElementById("sourceTitle"),
  wordPrefix: document.getElementById("wordPrefix"),
  wordOrp: document.getElementById("wordOrp"),
  wordSuffix: document.getElementById("wordSuffix"),
  rsvpHint: document.getElementById("rsvpHint"),
  wordProgress: document.getElementById("wordProgress"),
  timeRemaining: document.getElementById("timeRemaining"),
  progressScrubber: document.getElementById("progressScrubber"),
  btnPlayPause: document.getElementById("btnPlayPause"),
  playIcon: document.getElementById("playIcon"),
  pauseIcon: document.getElementById("pauseIcon"),
  btnRewind: document.getElementById("btnRewind"),
  btnForward: document.getElementById("btnForward"),
  wpmSlider: document.getElementById("wpmSlider"),
  wpmNumber: document.getElementById("wpmNumber"),
  wpmChips: document.querySelectorAll(".chip-btn"),
  btnOpenPdf: document.getElementById("btnOpenPdf"),
  pdfFileInput: document.getElementById("pdfFileInput"),
  dropOverlay: document.getElementById("dropOverlay"),
  btnShowQrCode: document.getElementById("btnShowQrCode"),
  qrCodeModal: document.getElementById("qrCodeModal"),
  btnCloseQr: document.getElementById("btnCloseQr"),
  qrCodeImg: document.getElementById("qrCodeImg"),
  btnSidePanel: document.getElementById("btnSidePanel"),
  btnThemeToggle: document.getElementById("btnThemeToggle")
};

let currentArticle = {
  title: "Carregando...",
  text: "",
  url: ""
};

// Instancia o RSVP Engine
const rsvp = new RSVPEngine({
  wpm: 350,
  smartPacing: true,
  onWordChange: (state) => {
    dom.wordPrefix.textContent = state.parts.prefix;
    dom.wordOrp.textContent = state.parts.orp;
    dom.wordSuffix.textContent = state.parts.suffix;

    dom.wordProgress.textContent = `${state.index + 1} / ${state.total} palavras`;
    dom.timeRemaining.textContent = `~${state.remainingMinutes} min`;

    if (state.total > 0) {
      dom.progressScrubber.value = Math.round((state.index / (state.total - 1)) * 100);
    }
  },
  onStateChange: (state) => {
    if (state.isPlaying) {
      dom.playIcon.style.display = "none";
      dom.pauseIcon.style.display = "block";
      dom.rsvpHint.style.opacity = "0";
    } else {
      dom.playIcon.style.display = "block";
      dom.pauseIcon.style.display = "none";
      dom.rsvpHint.style.opacity = "0.8";
    }
  },
  onComplete: () => {
    dom.wordPrefix.textContent = "";
    dom.wordOrp.textContent = "Concluído!";
    dom.wordSuffix.textContent = "";
    dom.rsvpHint.textContent = "Leitura finalizada! Pressione Espaço para reiniciar";
  }
});

// Inicialização
document.addEventListener("DOMContentLoaded", async () => {
  await loadSavedPreferences();
  await initActiveTabContent();
  setupEventListeners();
});

function showToast(message) {
  let toast = document.querySelector(".toast-notification");
  if (!toast) {
    toast = document.createElement("div");
    toast.className = "toast-notification";
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add("show");
  setTimeout(() => toast.classList.remove("show"), 2500);
}

// Carrega preferências salvas no storage
async function loadSavedPreferences() {
  const data = await chrome.storage.local.get(["wpm", "theme"]);
  if (data.wpm) {
    updateWPM(data.wpm);
  }
  if (data.theme) {
    applyTheme(data.theme);
  }
}

// Extrai o conteúdo da aba ativa ou detecta/processa PDF
async function initActiveTabContent() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

    if (!tab || !tab.id) {
      loadFallbackContent("Bem-vindo ao OneWord");
      return;
    }

    const tabUrl = (tab.url || "").trim();

    // 1. Detecta se a aba é diretamente um arquivo ou link de PDF
    const isDirectPdf = tabUrl.toLowerCase().endsWith(".pdf") || 
                        tabUrl.toLowerCase().includes(".pdf?") ||
                        (tabUrl.startsWith("file://") && tabUrl.toLowerCase().includes(".pdf"));

    if (isDirectPdf) {
      dom.sourceTitle.textContent = "Carregando PDF da página...";
      try {
        const pdfData = await extractPDFTextFromUrl(tabUrl, (page, total) => {
          dom.sourceTitle.textContent = `Lendo PDF: pág. ${page}/${total}...`;
        });

        currentArticle = {
          title: pdfData.title || tab.title || "Documento PDF",
          text: pdfData.text,
          url: tabUrl
        };
        dom.sourceTitle.textContent = `📄 ${currentArticle.title} (${pdfData.numPages} págs)`;
        rsvp.loadText(currentArticle.text);
        await chrome.storage.local.set({ currentArticle });
        showToast(`✅ PDF lido com sucesso (${pdfData.numPages} págs)!`);
        return;
      } catch (pdfErr) {
        console.warn("[OneWord] Falha ao baixar PDF diretamente da URL:", pdfErr);
        if (tabUrl.startsWith("file://")) {
          dom.sourceTitle.textContent = "📄 PDF local: clique no botão 📄 ou arraste o arquivo aqui";
          showToast("Dica: Use o botão 📄 acima para selecionar o arquivo PDF");
          return;
        }
      }
    }

    if (tabUrl.startsWith("chrome://") || tabUrl.startsWith("edge://")) {
      loadFallbackContent("Bem-vindo ao OneWord");
      return;
    }

    // Injeta script para extrair seleção ou artigo
    const results = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: extractTabContent
    });

    const extracted = results?.[0]?.result;

    // 2. Se a página continha um embed ou visualizador de PDF
    if (extracted?.isPdf && extracted?.pdfUrl) {
      dom.sourceTitle.textContent = "Carregando PDF detectado...";
      try {
        const pdfData = await extractPDFTextFromUrl(extracted.pdfUrl, (page, total) => {
          dom.sourceTitle.textContent = `Lendo PDF: pág. ${page}/${total}...`;
        });
        currentArticle = {
          title: pdfData.title || extracted.title || tab.title || "Documento PDF",
          text: pdfData.text,
          url: extracted.pdfUrl
        };
        dom.sourceTitle.textContent = `📄 ${currentArticle.title} (${pdfData.numPages} págs)`;
        rsvp.loadText(currentArticle.text);
        await chrome.storage.local.set({ currentArticle });
        showToast(`✅ PDF lido com sucesso (${pdfData.numPages} págs)!`);
        return;
      } catch (err) {
        console.warn("[OneWord] Erro ao extrair PDF do embed:", err);
      }
    }

    if (extracted && extracted.text && extracted.text.length > 20) {
      currentArticle = {
        title: extracted.title || tab.title || "Artigo Web",
        text: extracted.text,
        url: tab.url || ""
      };
      dom.sourceTitle.textContent = currentArticle.title;
      rsvp.loadText(currentArticle.text);

      // Salva no storage para sincronizar com o Side Panel
      await chrome.storage.local.set({ currentArticle });
    } else {
      loadFallbackContent(tab.title);
    }
  } catch (err) {
    console.warn("[OneWord] Falha ao extrair página ativa:", err);
    loadFallbackContent("OneWord RSVP Reader");
  }
}

// Processa arquivo PDF carregado via Input ou Drag & Drop
async function processPdfFile(file) {
  if (!file) return;
  if (!file.name.toLowerCase().endsWith(".pdf") && file.type !== "application/pdf") {
    showToast("⚠️ Por favor selecione um arquivo .pdf válido");
    return;
  }

  rsvp.pause();
  dom.sourceTitle.textContent = `Lendo ${file.name}...`;
  showToast("📄 Extraindo texto do PDF...");

  try {
    const pdfData = await extractPDFTextFromFile(file, (page, total) => {
      dom.sourceTitle.textContent = `Extraindo: pág. ${page}/${total}...`;
    });

    currentArticle = {
      title: pdfData.title || file.name,
      text: pdfData.text,
      url: ""
    };

    dom.sourceTitle.textContent = `📄 ${currentArticle.title} (${pdfData.numPages} págs)`;
    rsvp.loadText(currentArticle.text);
    await chrome.storage.local.set({ currentArticle });
    showToast(`✅ ${pdfData.numPages} páginas carregadas!`);
  } catch (err) {
    console.error("[OneWord] Erro ao processar PDF:", err);
    showToast("❌ Erro ao ler PDF: " + (err.message || "arquivo protegido ou imagem"));
    dom.sourceTitle.textContent = "Erro ao processar PDF";
  }
}

function loadFallbackContent(title) {
  const fallbackText = "O OneWord permite ler artigos e livros na velocidade do pensamento através da técnica RSVP e guias foveais ORP. Selecione qualquer texto em uma página web, abra um arquivo PDF pelo botão 📄 ou clique em 'Enviar para o iPhone' para ler no celular.";
  currentArticle = {
    title: title || "OneWord RSVP Reader",
    text: fallbackText,
    url: ""
  };
  dom.sourceTitle.textContent = currentArticle.title;
  rsvp.loadText(fallbackText);
}

// Configura listeners de eventos e atalhos
function setupEventListeners() {
  // Play / Pause
  dom.btnPlayPause.addEventListener("click", () => rsvp.toggle());

  // Step -10 / +10
  dom.btnRewind.addEventListener("click", () => rsvp.step(-10));
  dom.btnForward.addEventListener("click", () => rsvp.step(10));

  // Scrubber de Progresso
  dom.progressScrubber.addEventListener("input", (e) => {
    if (rsvp.words.length === 0) return;
    const targetIdx = Math.round((parseInt(e.target.value, 10) / 100) * (rsvp.words.length - 1));
    rsvp.seek(targetIdx);
  });

  // Slider de WPM
  dom.wpmSlider.addEventListener("input", (e) => {
    updateWPM(parseInt(e.target.value, 10));
  });

  // Chips de WPM
  dom.wpmChips.forEach((chip) => {
    chip.addEventListener("click", () => {
      const val = parseInt(chip.dataset.wpm, 10);
      updateWPM(val);
    });
  });

  // Botão Abrir Arquivo PDF
  if (dom.btnOpenPdf && dom.pdfFileInput) {
    dom.btnOpenPdf.addEventListener("click", () => {
      dom.pdfFileInput.click();
    });

    dom.pdfFileInput.addEventListener("change", async (e) => {
      const file = e.target.files?.[0];
      if (file) {
        await processPdfFile(file);
        dom.pdfFileInput.value = "";
      }
    });
  }

  // Suporte a Drag & Drop de PDFs na janela do popup
  window.addEventListener("dragover", (e) => {
    e.preventDefault();
    if (dom.dropOverlay) {
      dom.dropOverlay.classList.remove("hidden");
    }
  });

  window.addEventListener("dragleave", (e) => {
    if (e.relatedTarget === null && dom.dropOverlay) {
      dom.dropOverlay.classList.add("hidden");
    }
  });

  window.addEventListener("drop", async (e) => {
    e.preventDefault();
    if (dom.dropOverlay) {
      dom.dropOverlay.classList.add("hidden");
    }
    const file = e.dataTransfer?.files?.[0];
    if (file) {
      await processPdfFile(file);
    }
  });


  // QR Code Instantâneo para Câmera do iPhone (Abre diretamente via Deep Link oneword://)
  if (dom.btnShowQrCode && dom.qrCodeModal) {
    dom.btnShowQrCode.addEventListener("click", () => {
      rsvp.pause();
      let targetUrl = currentArticle.url;
      if (targetUrl && !targetUrl.startsWith("chrome") && !targetUrl.startsWith("file")) {
        targetUrl = `oneword://open?url=${encodeURIComponent(targetUrl)}`;
      } else {
        const textSample = (currentArticle.text || "").slice(0, 300);
        targetUrl = `oneword://read?text=${encodeURIComponent(textSample)}&title=${encodeURIComponent(currentArticle.title || "Artigo")}`;
      }
      dom.qrCodeImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(targetUrl)}`;
      dom.qrCodeModal.classList.remove("hidden");
    });
  }

  if (dom.btnCloseQr && dom.qrCodeModal) {
    dom.btnCloseQr.addEventListener("click", () => {
      dom.qrCodeModal.classList.add("hidden");
    });
  }

  // Botão: Abrir no Side Panel
  dom.btnSidePanel.addEventListener("click", async () => {
    const currentWindow = await chrome.windows.getCurrent();
    await chrome.runtime.sendMessage({
      action: "openSidePanel",
      windowId: currentWindow.id
    });
    window.close(); // Fecha o popup para dar foco ao side panel
  });

  // Alternar Tema (Dark -> Light -> Sepia -> Dark)
  dom.btnThemeToggle.addEventListener("click", async () => {
    const currentTheme = document.body.className;
    let nextTheme = "theme-dark";
    if (currentTheme.includes("theme-dark")) {
      nextTheme = "theme-light";
    } else if (currentTheme.includes("theme-light")) {
      nextTheme = "theme-sepia";
    } else {
      nextTheme = "theme-dark";
    }
    applyTheme(nextTheme);
    await chrome.storage.local.set({ theme: nextTheme });
  });

  // Atalhos de teclado no popup
  window.addEventListener("keydown", (e) => {
    if (e.code === "Space") {
      e.preventDefault();
      rsvp.toggle();
    } else if (e.code === "ArrowLeft") {
      e.preventDefault();
      rsvp.step(-10);
    } else if (e.code === "ArrowRight") {
      e.preventDefault();
      rsvp.step(10);
    } else if (e.code === "ArrowUp") {
      e.preventDefault();
      updateWPM(rsvp.wpm + 25);
    } else if (e.code === "ArrowDown") {
      e.preventDefault();
      updateWPM(rsvp.wpm - 25);
    }
  });
}

function updateWPM(val) {
  const clamped = Math.max(100, Math.min(1000, val));
  rsvp.setWPM(clamped);
  dom.wpmSlider.value = clamped;
  dom.wpmNumber.textContent = clamped;

  dom.wpmChips.forEach((chip) => {
    if (parseInt(chip.dataset.wpm, 10) === clamped) {
      chip.classList.add("active");
    } else {
      chip.classList.remove("active");
    }
  });

  chrome.storage.local.set({ wpm: clamped });
}

function applyTheme(themeName) {
  document.body.className = themeName;
}

// Função de extração do documento executada no contexto da página da aba
function extractTabContent() {
  // 1. Detecta páginas servidas com cabeçalho application/pdf ou links diretos
  if (document.contentType === "application/pdf" || window.location.href.toLowerCase().endsWith(".pdf")) {
    return {
      isPdf: true,
      pdfUrl: window.location.href,
      title: document.title || "Documento PDF"
    };
  }

  const embed = document.querySelector("embed[type='application/pdf'], embed[src*='.pdf'], iframe[src*='.pdf']");
  if (embed && embed.src) {
    return {
      isPdf: true,
      pdfUrl: embed.src,
      title: document.title || "Documento PDF"
    };
  }

  const selection = window.getSelection()?.toString()?.trim();
  if (selection && selection.length > 25) {
    return {
      text: selection,
      title: document.title || "Seleção"
    };
  }

  const title = (
    document.querySelector("h1")?.innerText ||
    document.querySelector("meta[property='og:title']")?.content ||
    document.title ||
    "Artigo da Web"
  ).trim();

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

  const clone = targetElement.cloneNode(true);
  const elementsToRemove = clone.querySelectorAll(
    "script, style, noscript, nav, header, footer, aside, svg, form, iframe, button, [aria-hidden='true']"
  );
  elementsToRemove.forEach(el => el.remove());

  const paragraphs = Array.from(clone.querySelectorAll("p, h1, h2, h3, h4, h5, h6, li, blockquote"))
    .map(p => p.innerText.trim())
    .filter(text => text.length > 0);

  const cleanText = paragraphs.length > 0 ? paragraphs.join("\n\n") : (clone.innerText || "").trim();

  return {
    text: cleanText,
    title: title
  };
}
