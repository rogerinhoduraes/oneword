//
//  app.js
//  OneWord Cloud Web RSVP Controller
//

import { RSVPEngine } from "./rsvp-engine.js";

const dom = {
  sidebar: document.getElementById("sidebar"),
  btnToggleSidebar: document.getElementById("btnToggleSidebar"),
  btnRefreshList: document.getElementById("btnRefreshList"),
  articlesList: document.getElementById("articlesList"),
  currentArticleTitle: document.getElementById("currentArticleTitle"),
  currentArticleMeta: document.getElementById("currentArticleMeta"),
  wordPrefix: document.getElementById("wordPrefix"),
  wordOrp: document.getElementById("wordOrp"),
  wordSuffix: document.getElementById("wordSuffix"),
  rsvpInstruction: document.getElementById("rsvpInstruction"),
  wordProgressText: document.getElementById("wordProgressText"),
  readingTimeLeft: document.getElementById("readingTimeLeft"),
  progressScrubber: document.getElementById("progressScrubber"),
  btnPlayPause: document.getElementById("btnPlayPause"),
  playIcon: document.getElementById("playIcon"),
  pauseIcon: document.getElementById("pauseIcon"),
  btnRewind: document.getElementById("btnRewind"),
  btnForward: document.getElementById("btnForward"),
  wpmSlider: document.getElementById("wpmSlider"),
  wpmValue: document.getElementById("wpmValue"),
  chips: document.querySelectorAll(".chip"),
  btnThemeToggle: document.getElementById("btnThemeToggle")
};

let articles = [];
let activeArticle = null;

const rsvp = new RSVPEngine({
  wpm: 350,
  smartPacing: true,
  onWordChange: (state) => {
    dom.wordPrefix.textContent = state.parts.prefix;
    dom.wordOrp.textContent = state.parts.orp;
    dom.wordSuffix.textContent = state.parts.suffix;

    dom.wordProgressText.textContent = `${state.index + 1} / ${state.total}`;
    dom.readingTimeLeft.textContent = `~${state.remainingMinutes} min`;

    if (state.total > 0) {
      dom.progressScrubber.value = Math.round((state.index / (state.total - 1)) * 100);
    }
  },
  onStateChange: (state) => {
    if (state.isPlaying) {
      dom.playIcon.style.display = "none";
      dom.pauseIcon.style.display = "block";
      dom.rsvpInstruction.style.opacity = "0";
    } else {
      dom.playIcon.style.display = "block";
      dom.pauseIcon.style.display = "none";
      dom.rsvpInstruction.style.opacity = "0.8";
    }
  },
  onComplete: () => {
    dom.wordPrefix.textContent = "";
    dom.wordOrp.textContent = "Concluído!";
    dom.wordSuffix.textContent = "";
    dom.rsvpInstruction.textContent = "Leitura finalizada! Pressione Espaço para reiniciar";
  }
});

document.addEventListener("DOMContentLoaded", async () => {
  setupEventListeners();
  await loadArticles();
});

async function loadArticles() {
  try {
    const res = await fetch("/api/articles");
    if (!res.ok) throw new Error("Falha ao carregar artigos");
    articles = await res.json();
    renderArticlesList();
    if (articles.length > 0 && !activeArticle) {
      selectArticle(articles[0]);
    }
  } catch (err) {
    dom.articlesList.innerHTML = `<div class="loading-state" style="color: #ef4444;">Erro ao carregar: ${err.message}</div>`;
  }
}

function renderArticlesList() {
  if (articles.length === 0) {
    dom.articlesList.innerHTML = `<div class="loading-state">Nenhum artigo salvo ainda.<br>Envie da extensão do Chrome!</div>`;
    return;
  }

  dom.articlesList.innerHTML = articles.map(art => {
    const isActive = activeArticle && activeArticle.id === art.id;
    const dateStr = new Date(art.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    return `
      <div class="article-item ${isActive ? 'active' : ''}" data-id="${art.id}">
        <span class="article-item-title">${escapeHTML(art.title)}</span>
        <div class="article-item-meta">
          <span>${art.words} palavras</span>
          <span>${dateStr}</span>
        </div>
      </div>
    `;
  }).join("");

  dom.articlesList.querySelectorAll(".article-item").forEach(el => {
    el.addEventListener("click", () => {
      const art = articles.find(a => a.id === el.dataset.id);
      if (art) selectArticle(art);
    });
  });
}

function selectArticle(article) {
  activeArticle = article;
  dom.currentArticleTitle.textContent = article.title;
  const mins = (article.words / rsvp.wpm).toFixed(1);
  dom.currentArticleMeta.textContent = `${article.words} palavras • ~${mins} min`;

  rsvp.loadText(article.text);
  renderArticlesList();
}

function setupEventListeners() {
  dom.btnToggleSidebar.addEventListener("click", () => {
    dom.sidebar.classList.toggle("closed");
  });

  dom.btnRefreshList.addEventListener("click", () => loadArticles());

  dom.btnPlayPause.addEventListener("click", () => rsvp.toggle());
  dom.btnRewind.addEventListener("click", () => rsvp.step(-10));
  dom.btnForward.addEventListener("click", () => rsvp.step(10));

  dom.progressScrubber.addEventListener("input", (e) => {
    if (rsvp.words.length === 0) return;
    const targetIdx = Math.round((parseInt(e.target.value, 10) / 100) * (rsvp.words.length - 1));
    rsvp.seek(targetIdx);
  });

  dom.wpmSlider.addEventListener("input", (e) => updateWPM(parseInt(e.target.value, 10)));

  dom.chips.forEach(chip => {
    chip.addEventListener("click", () => updateWPM(parseInt(chip.dataset.wpm, 10)));
  });

  dom.btnThemeToggle.addEventListener("click", () => {
    const current = document.body.className;
    if (current.includes("theme-dark")) {
      document.body.className = "theme-light";
    } else if (current.includes("theme-light")) {
      document.body.className = "theme-sepia";
    } else {
      document.body.className = "theme-dark";
    }
  });

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
  const clamped = Math.max(100, Math.min(1200, val));
  rsvp.setWPM(clamped);
  dom.wpmSlider.value = clamped;
  dom.wpmValue.textContent = clamped;

  dom.chips.forEach(chip => {
    if (parseInt(chip.dataset.wpm, 10) === clamped) {
      chip.classList.add("active");
    } else {
      chip.classList.remove("active");
    }
  });

  if (activeArticle) {
    const mins = (activeArticle.words / clamped).toFixed(1);
    dom.currentArticleMeta.textContent = `${activeArticle.words} palavras • ~${mins} min`;
  }
}

function escapeHTML(str) {
  return (str || "").replace(/[&<>"']/g, m => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;"
  })[m]);
}
