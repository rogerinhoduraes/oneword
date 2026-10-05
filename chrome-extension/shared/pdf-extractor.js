//
//  pdf-extractor.js
//  OneWord Chrome Extension - Extrator de Texto de Arquivos PDF
//

/**
 * Configura o worker do PDF.js caso esteja disponível no ambiente.
 */
export function initPDFWorker() {
  if (typeof window !== "undefined" && window.pdfjsLib) {
    try {
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = chrome.runtime.getURL("lib/pdf.worker.min.js");
    } catch (err) {
      console.warn("[OneWord PDF] Falha ao configurar workerSrc:", err);
    }
  }
}

/**
 * Extrai texto completo de um ArrayBuffer de PDF página a página.
 * @param {ArrayBuffer} buffer
 * @param {Function} [onProgress] - callback (paginaAtual, totalPaginas)
 * @returns {Promise<{numPages: number, text: string}>}
 */
export async function extractPDFTextFromBuffer(buffer, onProgress = null) {
  initPDFWorker();

  if (!window.pdfjsLib) {
    throw new Error("Biblioteca PDF.js não inicializada");
  }

  const loadingTask = window.pdfjsLib.getDocument({
    data: new Uint8Array(buffer),
    cMapPacked: true
  });

  const pdf = await loadingTask.promise;
  const numPages = pdf.numPages;
  const pagesText = [];

  for (let pageNum = 1; pageNum <= numPages; pageNum++) {
    if (onProgress) {
      onProgress(pageNum, numPages);
    }
    const page = await pdf.getPage(pageNum);
    const textContent = await page.getTextContent();
    
    // Normaliza espaçamento entre fragmentos de texto do PDF
    let lastY = null;
    let pageLines = [];
    let currentLine = [];

    for (const item of textContent.items) {
      if (!item.str) continue;
      
      const itemY = item.transform ? item.transform[5] : null;
      if (lastY !== null && itemY !== null && Math.abs(itemY - lastY) > 5) {
        // Nova linha física no PDF
        if (currentLine.length > 0) {
          pageLines.push(currentLine.join(" "));
          currentLine = [];
        }
      }
      currentLine.push(item.str.trim());
      lastY = itemY;
    }

    if (currentLine.length > 0) {
      pageLines.push(currentLine.join(" "));
    }

    const cleanContent = pageLines.join("\n").trim();
    if (cleanContent.length > 0) {
      pagesText.push(cleanContent);
    }
  }

  const fullText = pagesText.join("\n\n");
  if (!fullText || fullText.trim().length === 0) {
    throw new Error("O PDF não contém texto selecionável (pode ser um documento digitalizado/imagem).");
  }

  return {
    numPages,
    text: fullText
  };
}

/**
 * Extrai texto de um objeto File (seleção local ou drag & drop).
 * @param {File} file
 * @param {Function} [onProgress]
 */
export async function extractPDFTextFromFile(file, onProgress = null) {
  const buffer = await file.arrayBuffer();
  const result = await extractPDFTextFromBuffer(buffer, onProgress);
  const cleanTitle = file.name.replace(/\.pdf$/i, "").replace(/[_-]/g, " ");

  return {
    title: cleanTitle || "Documento PDF",
    numPages: result.numPages,
    text: result.text
  };
}

/**
 * Tenta baixar e extrair o texto de uma URL remota de PDF.
 * @param {string} url
 * @param {Function} [onProgress]
 */
export async function extractPDFTextFromUrl(url, onProgress = null) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Falha no download do PDF (${response.status})`);
  }
  const buffer = await response.arrayBuffer();
  const result = await extractPDFTextFromBuffer(buffer, onProgress);

  let filename = "Artigo PDF";
  try {
    const rawName = url.split("/").pop()?.split("?")[0] || "";
    if (rawName.toLowerCase().endsWith(".pdf")) {
      filename = decodeURIComponent(rawName.replace(/\.pdf$/i, "").replace(/[_-]/g, " "));
    }
  } catch (e) {}

  return {
    title: filename,
    numPages: result.numPages,
    text: result.text
  };
}
