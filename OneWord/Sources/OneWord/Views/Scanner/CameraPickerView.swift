//
//  CameraPickerView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// Envoltório representável em SwiftUI para o UIImagePickerController nativo com suporte a captura de câmera.
public struct CameraPickerView: UIViewControllerRepresentable {
    @Binding public var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            // Fallback para galeria em simulador sem câmera física
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    public final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
