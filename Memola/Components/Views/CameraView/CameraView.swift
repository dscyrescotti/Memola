//
//  CameraView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/15/24.
//

import SwiftUI

#if os(iOS)
struct CameraView: UIViewControllerRepresentable {
    @Binding private var image: UIImage?

    @ObservedObject private var canvas: Canvas

    @Environment(\.dismiss) private var dismiss

    init(image: Binding<UIImage?>, canvas: Canvas) {
        self._image = image
        self.canvas = canvas
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.image = (info[.originalImage] as? UIImage)?.imageWithUpOrientation()
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
