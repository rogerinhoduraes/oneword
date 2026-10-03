//
//  UIImage+Orientation.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

#if canImport(UIKit)
import UIKit
import ImageIO

public extension UIImage {
    /// Converte a orientação nativa do UIImage (`UIImage.Orientation`) para o formato
    /// correspondente exigido pelo Core Graphics e Vision Framework (`CGImagePropertyOrientation`).
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
#endif
