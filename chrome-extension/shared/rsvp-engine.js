//
//  rsvp-engine.js
//  OneWord Web RSVP Engine
//

export function calculateORPIndex(word) {
  if (!word || word.length === 0) return 0;
  // Limpa pontuações para achar o centro da palavra real
  const clean = word.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, "");
  const len = clean.length || word.length;

  let orpInClean = 0;
  if (len <= 1) {
    orpInClean = 0;
  } else if (len <= 5) {
    orpInClean = 1; // 2ª letra
  } else if (len <= 9) {
    orpInClean = 2; // 3ª letra
  } else if (len <= 13) {
    orpInClean = 3; // 4ª letra
  } else {
    orpInClean = 4; // 5ª letra
  }

  // Mapeia de volta para a palavra com pontuações prefixadas
  const leadingPunct = word.match(/^[^\p{L}\p{N}]+/u);
  const leadingOffset = leadingPunct ? leadingPunct[0].length : 0;
  return Math.min(leadingOffset + orpInClean, word.length - 1);
}

export function splitWordORP(word) {
  if (!word || word.length === 0) {
    return { prefix: "", orp: "", suffix: "" };
  }
  const idx = calculateORPIndex(word);
  return {
    prefix: word.slice(0, idx),
    orp: word.charAt(idx),
    suffix: word.slice(idx + 1)
  };
}

export class RSVPEngine {
  constructor(options = {}) {
    this.words = [];
    this.currentIndex = 0;
    this.wpm = options.wpm || 350;
    this.smartPacing = options.smartPacing !== false;
    this.isPlaying = false;
    this.timer = null;

    this.onWordChange = options.onWordChange || (() => {});
    this.onStateChange = options.onStateChange || (() => {});
    this.onComplete = options.onComplete || (() => {});
  }

  loadText(rawText) {
    if (!rawText) {
      this.words = [];
      this.currentIndex = 0;
      return;
    }
    // Tokeniza palavras preservando hífens e pontuação
    this.words = rawText
      .trim()
      .split(/\s+/)
      .filter(w => w.length > 0);
    this.currentIndex = 0;
    this.pause();
    this.emitCurrentWord();
  }

  start() {
    if (this.words.length === 0 || this.isPlaying) return;
    if (this.currentIndex >= this.words.length) {
      this.currentIndex = 0;
    }
    this.isPlaying = true;
    this.onStateChange({ isPlaying: true });
    this.scheduleNext();
  }

  pause() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    if (this.isPlaying) {
      this.isPlaying = false;
      this.onStateChange({ isPlaying: false });
    }
  }

  toggle() {
    if (this.isPlaying) {
      this.pause();
    } else {
      this.start();
    }
  }

  seek(index) {
    const clamped = Math.max(0, Math.min(index, this.words.length - 1));
    this.currentIndex = clamped;
    this.emitCurrentWord();
  }

  step(delta) {
    this.seek(this.currentIndex + delta);
  }

  setWPM(newWpm) {
    this.wpm = Math.max(100, Math.min(1200, newWpm));
    if (this.isPlaying) {
      clearTimeout(this.timer);
      this.scheduleNext();
    }
  }

  scheduleNext() {
    if (!this.isPlaying) return;

    if (this.currentIndex >= this.words.length) {
      this.pause();
      this.onComplete();
      return;
    }

    const currentWord = this.words[this.currentIndex];
    this.emitCurrentWord();

    const delay = this.calculateWordDelay(currentWord);

    this.timer = setTimeout(() => {
      this.currentIndex++;
      this.scheduleNext();
    }, delay);
  }

  calculateWordDelay(word) {
    const baseMs = (60 * 1000) / this.wpm;
    if (!this.smartPacing || !word) return baseMs;

    let multiplier = 1.0;

    // Pausa por pontuação final (. ? ! …)
    if (/[.?!…]$/.test(word)) {
      multiplier += 0.7; // +70% de tempo para fechamento semântico
    }
    // Pausa média (, ; : —)
    else if (/[,;:\u2014-]$/.test(word)) {
      multiplier += 0.35; // +35%
    }

    // Palavras longas (> 10 caracteres) demandam mais processamento foveal
    if (word.length > 10) {
      multiplier += 0.2;
    }

    return baseMs * multiplier;
  }

  emitCurrentWord() {
    const word = this.words[this.currentIndex] || "";
    const parts = splitWordORP(word);
    this.onWordChange({
      word,
      parts,
      index: this.currentIndex,
      total: this.words.length,
      progress: this.words.length > 0 ? (this.currentIndex / this.words.length) : 0,
      remainingMinutes: this.calculateRemainingMinutes()
    });
  }

  calculateRemainingMinutes() {
    const wordsLeft = Math.max(0, this.words.length - this.currentIndex);
    return (wordsLeft / this.wpm).toFixed(1);
  }
}
