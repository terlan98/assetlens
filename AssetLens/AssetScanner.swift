//
//  AssetScanner.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

struct AssetScanner {
    let supportedExtensions = ["png", "jpg", "jpeg", "pdf", "svg"]
    
    func scanDirectory(at url: URL, minSizeKB: Int) throws -> [ImageAsset] {
        var assets: [ImageAsset] = []
        var processedImagesets = Set<String>() // Track imagesets we've already processed
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AssetLensError.cannotReadDirectory(url.path)
        }
        
        for case let fileURL as URL in enumerator {
            // Skip non-image files
            guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }
            
            // Check file size
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               fileSize < minSizeKB * 1024 {
                continue
            }
            
            // Skip Launch images and generated files
            let filename = fileURL.lastPathComponent
            if filename.contains("LaunchImage") ||
               filename.contains(".generated.") ||
               filename.contains("~") {
                continue
            }
            
            let asset = ImageAsset(url: fileURL)
            
            // If this is part of an imageset, only include one representative image
            if let imagesetName = asset.imagesetName {
                // Create a unique key for this imageset location
                let imagesetKey = asset.relativePath
                
                if !processedImagesets.contains(imagesetKey) {
                    processedImagesets.insert(imagesetKey)
                    assets.append(asset)
                }
                // Skip other images in the same imageset
            } else {
                // Not in an imageset, include it
                assets.append(asset)
            }
        }
        
        return assets
    }
}
