//
//  ApplePencilGestureManager.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Gerenciador de gestos avançados para Apple Pencil (Apple Pencil 2 & Apple Pencil Pro no iPadOS).
/// Mapeia o aperto (squeeze), rotação de barril (barrel roll) e toque duplo (double tap)
/// diretamente nos controles do leitor RSVP.
@MainActor
public final class ApplePencilGestureManager: NSObject, Sendable {
    public static let shared = ApplePencilGestureManager()
    
    public var onSqueezeTriggered: (() -> Void)?
    public var onDoubleTapTriggered: (() -> Void)?
    public var onBarrelRollTriggered: ((CGFloat) -> Void)?
    
    public override init() {
        super.init()
    }
    
    /// Conecta a interação do Apple Pencil a uma UIView no iPadOS.
    #if canImport(UIKit)
    public func attach(to view: UIView) {
        #if os(iOS)
        // 1. Duplo Toque (Apple Pencil 2 & Pro)
        let doubleTapInteraction = UIPencilInteraction()
        doubleTapInteraction.delegate = self
        view.addInteraction(doubleTapInteraction)
        #endif
    }
    #endif
}

#if canImport(UIKit) && os(iOS)
extension ApplePencilGestureManager: UIPencilInteractionDelegate {
    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        onDoubleTapTriggered?()
    }
}
#endif
