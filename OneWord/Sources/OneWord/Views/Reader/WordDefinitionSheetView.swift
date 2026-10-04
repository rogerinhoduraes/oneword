//
//  WordDefinitionSheetView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Apresentação do dicionário oficial da Apple ou modal de definição para o termo sob foco no leitor RSVP.
public struct WordDefinitionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let word: String
    
    public init(word: String) {
        // Remove pontuação externa para consulta no léxico
        self.word = word.trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
    }
    
    public var body: some View {
        #if os(iOS)
        SystemReferenceLibraryView(term: word)
            .ignoresSafeArea()
        #else
        macOSDefinitionFallback
        #endif
    }
    
    #if !os(iOS)
    private var macOSDefinitionFallback: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text(word)
                    .font(.largeTitle)
                    .bold()
                
                Text("Consulta ao dicionário do sistema Apple.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .frame(minWidth: 350, minHeight: 400)
    }
    #endif
}

#if os(iOS)
/// Envoltório SwiftUI para o controlador oficial do dicionário da Apple (`UIReferenceLibraryViewController`).
struct SystemReferenceLibraryView: UIViewControllerRepresentable {
    let term: String
    
    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }
    
    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
#endif
