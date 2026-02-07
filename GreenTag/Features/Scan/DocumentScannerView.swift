//
//  DocumentScannerView.swift
//  GreenTag
//
//  Created by Cheyenne Chau on 2/7/26.
//

import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onComplete: ([UIImage]) -> Void
    var onCancel: () -> Void = {}
    var onError: (Error) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onError(error)
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                              didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            
            parent.onComplete(images)
            parent.dismiss()
        }
    }
}
