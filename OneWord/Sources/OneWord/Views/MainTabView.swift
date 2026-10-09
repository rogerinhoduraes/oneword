//
//  MainTabView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// TabView principal do aplicativo OneWord.
/// Alterna entre a Biblioteca de leitura, o Dashboard de Estatísticas/Produtividade e os Ajustes.
public struct MainTabView: View {
    public enum Tab: String, Hashable {
        case library
        case stats
        case settings
    }
    
    @State private var selectedTab: Tab
    
    public init(initialTab: Tab = .library) {
        let launchArg = UserDefaults.standard.string(forKey: "selectedTab")
        let tab: Tab
        if launchArg == "stats" {
            tab = .stats
        } else if launchArg == "settings" {
            tab = .settings
        } else {
            tab = initialTab
        }
        _selectedTab = State(initialValue: tab)
    }
    
    @Query private var books: [Book]
    
    public var body: some View {
        #if DEBUG
        Group {
            if UserDefaults.standard.bool(forKey: "previewBookDetail"), let firstBook = books.first {
                NavigationStack {
                    BookDetailView(book: firstBook)
                }
            } else {
                tabViewContent
            }
        }
        #else
        tabViewContent
        #endif
    }
    
    private var tabViewContent: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Biblioteca", systemImage: "books.vertical.fill")
                }
                .tag(Tab.library)
            
            StatsView()
                .tabItem {
                    Label("Estatísticas", systemImage: "chart.bar.xaxis")
                }
                .tag(Tab.stats)
            
            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(ModelContainer.preview)
}
