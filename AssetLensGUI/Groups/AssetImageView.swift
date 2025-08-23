//
//  AssetImageView.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 23.08.25.
//


import SwiftUI
import PDFKit
import AssetLensCore

struct AssetImageView: View {
    let asset: ImageAsset
    let size: CGFloat
    
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        Task {
            if let loadedImage = await loadImageFromDisk() {
                await MainActor.run {
                    self.image = loadedImage
                }
            }
        }
    }
    
    private func loadImageFromDisk() async -> NSImage? {
        let url = asset.url
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return loadPDFAsImage(from: url)
        default:
            return NSImage(contentsOf: url)
        }
    }
    
    private func loadPDFAsImage(from url: URL) -> NSImage? {
        guard let pdfDocument = PDFDocument(url: url),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let targetSize = NSSize(width: size * 2, height: size * 2) // 2x for retina
        let thumbnail = firstPage.thumbnail(of: targetSize, for: .mediaBox)
        
        return thumbnail
    }
}
