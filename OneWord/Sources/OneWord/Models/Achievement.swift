//
//  Achievement.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Modelo de conquista e medalha desbloqueável de leitura e foco.
public struct Achievement: Identifiable, Sendable, Codable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let category: String
    public var isUnlocked: Bool
    public var unlockedAt: Date?
    public var progress: Double // 0.0 a 1.0
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        category: String,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.progress = progress
    }
}
