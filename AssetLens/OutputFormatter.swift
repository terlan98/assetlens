//
//  OutputFormatter.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

struct OutputFormatter {
    let format: AssetLens.OutputFormat
    let verbose: Bool
    
    func output(groups: [SimilarityGroup], from baseURL: URL) {
        switch format {
        case .text:
            outputText(groups: groups, from: baseURL)
        case .json:
            outputJSON(groups: groups, from: baseURL)
        case .xcode:
            outputXcode(groups: groups, from: baseURL)
        }
    }
    
    private func outputText(groups: [SimilarityGroup], from baseURL: URL) {
        if groups.isEmpty {
            print("✅ No similar assets found")
            return
        }
        
        print("\n🔍 Found \(groups.count) group(s) of similar assets:\n")
        
        for (index, group) in groups.enumerated() {
            print("Group \(index + 1):")
            print("  Primary: \(group.primary.displayName)")
            
            let totalSize = group.totalSize
            let potentialSavings = group.potentialSavings
            
            for (asset, distance) in group.similar {
                if verbose {
                    print("  Similar: \(asset.displayName) (distance: \(String(format: "%.2f", distance)))")
                } else {
                    print("  Similar: \(asset.displayName)")
                }
            }
            
            print("  Total size: \(formatBytes(totalSize))")
            print("  Potential savings: \(formatBytes(potentialSavings))")
            print()
        }
        
        let totalSavings = groups.reduce(0) { $0 + $1.potentialSavings }
        print("💡 Total potential savings: \(formatBytes(totalSavings))")
    }
    
    private func outputJSON(groups: [SimilarityGroup], from baseURL: URL) {
        let output = groups.map { group in
            [
                "primary": group.primary.displayName,
                "primaryPath": formatAssetPath(group.primary, from: baseURL),
                "similar": group.similar.map { asset, distance in
                    [
                        "name": asset.displayName,
                        "path": formatAssetPath(asset, from: baseURL),
                        "distance": distance
                    ]
                },
                "totalSize": group.totalSize,
                "potentialSavings": group.potentialSavings
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
    
    private func outputXcode(groups: [SimilarityGroup], from baseURL: URL) {
        if groups.isEmpty {
            return
        }
        
        for group in groups {
            // For Xcode warnings, we need the actual file path
            let primaryPath = group.primary.url.path
            print("warning: \(primaryPath):1:1: Similar assets detected - \(group.primary.displayName)")
            
            for (asset, _) in group.similar {
                print("note: \(asset.url.path):1:1: Similar to \(group.primary.displayName)")
            }
        }
        
        let totalSavings = groups.reduce(0) { $0 + $1.potentialSavings }
        print("warning: Found \(groups.count) groups of similar assets. Potential savings: \(formatBytes(totalSavings))")
    }
    
    private func formatAssetPath(_ asset: ImageAsset, from baseURL: URL) -> String {
        // Use the asset's relative path which includes imageset handling
        let assetRelativePath = asset.relativePath
        
        // If it's already a good relative path (starts with .xcassets), use it
        if assetRelativePath.contains(".xcassets") {
            return assetRelativePath
        }
        
        // Otherwise, try to make it relative to the base URL
        let fullPath = asset.url.path
        let basePath = baseURL.path
        
        if fullPath.hasPrefix(basePath) {
            let relativePath = String(fullPath.dropFirst(basePath.count + 1))
            
            // If this is an imageset, truncate at the .imageset directory
            if let imagesetRange = relativePath.range(of: ".imageset") {
                return String(relativePath[...imagesetRange.lowerBound]) + "imageset"
            }
            
            return relativePath
        }
        
        // Fallback to display name
        return asset.displayName
    }
    
    private func relativePath(_ url: URL, from baseURL: URL) -> String {
        let path = url.path
        let basePath = baseURL.path
        
        if path.hasPrefix(basePath) {
            return String(path.dropFirst(basePath.count + 1))
        }
        return path
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
