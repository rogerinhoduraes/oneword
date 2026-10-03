//
//  VisionDocumentScannerView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

#if canImport(VisionKit) && canImport(UIKit)
import VisionKit
import UIKit

/// Envoltório representável do scanner de documentos nativo da Apple (VisionKit VNDocumentCameraViewController).
/// Oferece detecção automática das 4 bordas da folha de papel, correção de perspectiva,
/// remoção de sombras e realce de contraste de texto impresso (idêntico ao app Notas da Apple).
public struct VisionDocumentScannerView: UIViewControllerRepresentable {
    @Binding public var scannedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    public init(scannedImages: Binding<[UIImage]>) {
        self._scannedImages = scannedImages
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: VisionDocumentScannerView
        
        init(_ parent: VisionDocumentScannerView) {
            self.parent = parent
        }
        
        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.scannedImages = images
            parent.dismiss()
        }
        
        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            print("Erro no escaneamento de documento: \(error.localizedDescription)")
            parent.dismiss()
        }
    }
}
#endif
