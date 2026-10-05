//
//  BionicPacerView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Modo de Leitura Híbrida: Exibe o texto completo em formatação biônica (âncoras em negrito)
/// com um cursor de foco óptico (Pacer) que avança na cadência do WPM selecionado.
public struct BionicPacerView: View {
    @Bindable public var viewModel: RSVPReaderViewModel
    @State private var helper = BionicReadingHelper()
    
    public init(viewModel: RSVPReaderViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        let words = viewModel.engine.words
        let blockSize = 40
        let blocks: [(id: Int, startIndex: Int, words: [String])] = stride(from: 0, to: words.count, by: blockSize).map { start in
            let end = min(start + blockSize, words.count)
            return (id: start, startIndex: start, words: Array(words[start..<end]))
        }
        
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(blocks, id: \.id) { block in
                        FlowLayout(spacing: 8) {
                            ForEach(0..<block.words.count, id: \.self) { offset in
                                let idx = block.startIndex + offset
                                let word = block.words[offset]
                                let segment = helper.splitWord(word)
                                let isCurrent = idx == viewModel.currentIndex
                                
                                HStack(spacing: 0) {
                                    Text(segment.prefix)
                                        .bold()
                                        .foregroundColor(isCurrent ? .white : viewModel.settings.theme.textColor)
                                    Text(segment.suffix)
                                        .foregroundColor(isCurrent ? .white : viewModel.settings.theme.textColor.opacity(0.85))
                                }
                                .font(viewModel.settings.font.font(size: max(18, viewModel.settings.fontSize * 0.45)))
                                // Dimensões estáveis: padding idêntico ativo/inativo para eliminar reflow e tremor de texto
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(
                                    isCurrent ?
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(Color.accentColor)
                                    : nil
                                )
                                .id("word_\(idx)")
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.engine.seek(to: idx)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.currentIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.12)) {
                    proxy.scrollTo("word_\(newIndex)", anchor: .center)
                }
            }
        }
        .background(viewModel.settings.theme.backgroundColor)
    }
}

/// Layout em fluxo flexível para posicionar palavras horizontalmente com quebra de linha fluida.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
    }
}
