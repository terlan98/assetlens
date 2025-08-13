//
//  ImageAsset.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

struct ImageAsset {
    let url: URL
    var isUsed: Bool?
    
    var fileSize: Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
    }
    
    /// Returns the display name for the asset (imageset name if in .xcassets, otherwise filename)
    var displayName: String {
        // Check if this is part of an imageset
        if let imagesetName = imagesetName {
            return imagesetName
        }
        // Otherwise return the filename without extension
        return url.deletingPathExtension().lastPathComponent
    }
    
    /// Returns the imageset name if this asset is part of an .imageset directory
    var imagesetName: String? {
        // Check if this file is inside an .imageset directory
        let pathComponents = url.pathComponents
        
        // Find the .imageset component in the path
        if let imagesetIndex = pathComponents.firstIndex(where: { $0.hasSuffix(".imageset") }) {
            // Return the imageset name without the extension
            let imagesetComponent = pathComponents[imagesetIndex]
            return String(imagesetComponent.dropLast(".imageset".count))
        }
        
        return nil
    }
    
    /// Returns a user-friendly relative path including the imageset name
    var relativePath: String {
        // If it's in an imageset, show the path up to the imageset
        if let imagesetName = imagesetName {
            let pathComponents = url.pathComponents
            if let imagesetIndex = pathComponents.firstIndex(where: { $0.hasSuffix(".imageset") }) {
                // Build path up to and including the imageset
                let relevantComponents = pathComponents[0...imagesetIndex]
                
                // Find .xcassets in the path to make it relative from there
                if let xcassetsIndex = relevantComponents.firstIndex(where: { $0.hasSuffix(".xcassets") }) {
                    let fromXcassets = relevantComponents[(xcassetsIndex)...]
                    return fromXcassets.joined(separator: "/")
                }
            }
        }
        
        // Fallback to just the filename
        return url.lastPathComponent
    }
    
    /// Check if two assets are from the same imageset
    func isInSameImageset(as other: ImageAsset) -> Bool {
        guard let thisImageset = self.imagesetName,
              let otherImageset = other.imagesetName else {
            return false
        }
        return thisImageset == otherImageset
    }
}
