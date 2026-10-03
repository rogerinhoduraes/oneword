//
//  BookCoverView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Renderiza a capa tridimensional estilizada de um livro da biblioteca.
/// Exibe a fotografia física escaneada ou uma capa tipográfica minimalista com efeito de lombada.
public struct BookCoverView: View {
    public let title: String
    public let author: String
    public let coverImageData: Data?
    public let themeColorHex: String
    public let width: CGFloat
    public let height: CGFloat
    
    public init(
        title: String,
        author: String = "",
        coverImageData: Data? = nil,
        themeColorHex: String = "#1E40AF",
        width: CGFloat = 110,
        height: CGFloat = 160
    ) {
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.themeColorHex = themeColorHex
        self.width = width
        self.height = height
    }
    
    public var body: some View {
        ZStack {
            #if canImport(UIKit)
            if let coverImageData, let uiImage = UIImage(data: coverImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                minimalistProceduralCover
            }
            #else
            minimalistProceduralCover
            #endif
            
            // Efeito visual realista de lombada e vinco de encadernação
            spineOverlay
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 6, x: 2, y: 4)
    }
    
    // MARK: - Capa Tipográfica Minimalista
    
    private var minimalistProceduralCover: some View {
        let baseColor = Color(hex: themeColorHex)
        
        return ZStack {
            LinearGradient(
                colors: [baseColor, baseColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: width * 0.16))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 2)
                
                Text(title)
                    .font(.system(size: width * 0.11, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                if !author.isEmpty {
                    Text(author)
                        .font(.system(size: width * 0.08, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                // Emblema RSVP
                HStack {
                    Spacer()
                    Text("RSVP")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(.white.opacity(0.3), lineWidth: 0.8)
                        )
                }
            }
            .padding(10)
        }
    }
    
    // MARK: - Detalhe de Lombada
    
    private var spineOverlay: some View {
        HStack {
            // Sombra e reflexo simulando o relevo do vinco da capa dura
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.35),
                            Color.black.opacity(0.1),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(4, width * 0.06))
            
            Spacer()
        }
    }
}

// MARK: - Color Hex Extension

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 30, 64, 175)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
