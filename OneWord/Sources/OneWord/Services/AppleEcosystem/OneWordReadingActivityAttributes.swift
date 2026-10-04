//
//  OneWordReadingActivityAttributes.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

/// Atributos e estado dinâmico para Live Activities e Dynamic Island (Ilha Dinâmica do iPhone).
public struct OneWordReadingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var currentWord: String
        public var wordsRead: Int
        public var totalWords: Int
        public var remainingMinutes: Double
        public var wpm: Int
        public var isPlaying: Bool
        
        public init(
            currentWord: String,
            wordsRead: Int,
            totalWords: Int,
            remainingMinutes: Double,
            wpm: Int,
            isPlaying: Bool
        ) {
            self.currentWord = currentWord
            self.wordsRead = wordsRead
            self.totalWords = totalWords
            self.remainingMinutes = remainingMinutes
            self.wpm = wpm
            self.isPlaying = isPlaying
        }
        
        public var progressPercentage: Double {
            guard totalWords > 0 else { return 0 }
            return min(max(Double(wordsRead) / Double(totalWords), 0.0), 1.0)
        }
    }
    
    public var title: String
    public var author: String?
    
    public init(title: String, author: String? = nil) {
        self.title = title
        self.author = author
    }
}
#else
/// Fallback struct para compilação multiplataforma macOS/CLI.
public struct OneWordReadingActivityAttributes: Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var currentWord: String
        public var wordsRead: Int
        public var totalWords: Int
        public var remainingMinutes: Double
        public var wpm: Int
        public var isPlaying: Bool
        
        public init(
            currentWord: String,
            wordsRead: Int,
            totalWords: Int,
            remainingMinutes: Double,
            wpm: Int,
            isPlaying: Bool
        ) {
            self.currentWord = currentWord
            self.wordsRead = wordsRead
            self.totalWords = totalWords
            self.remainingMinutes = remainingMinutes
            self.wpm = wpm
            self.isPlaying = isPlaying
        }
    }
    
    public var title: String
    public var author: String?
    
    public init(title: String, author: String? = nil) {
        self.title = title
        self.author = author
    }
}
#endif
