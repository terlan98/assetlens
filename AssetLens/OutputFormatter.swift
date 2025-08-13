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
    
    func output(groups: [SimilarityGroup], allAssets: [ImageAsset], from baseURL: URL) {
        switch format {
        case .text:
            outputText(groups: groups, allAssets: allAssets, from: baseURL)
        case .json:
            outputJSON(groups: groups, allAssets: allAssets, from: baseURL)
        case .xcode:
            outputXcode(groups: groups, allAssets: allAssets, from: baseURL)
        }
    }
    
    private func outputText(groups: [SimilarityGroup], allAssets: [ImageAsset], from baseURL: URL) {
        // Similar assets section
        if groups.isEmpty {
            print("✅ No similar assets found")
        } else {
            print("\n🔍 Found \(groups.count) group(s) of similar assets:\n")
            
            for (index, group) in groups.enumerated() {
                print("Group \(index + 1):")
                print("  Primary: \(group.primary.displayName)\(group.primary.isUsed == false ? " - ⚠️ UNUSED" : "")")
                
                let totalSize = group.totalSize
                let potentialSavings = group.potentialSavings
                
                for (asset, distance) in group.similar {
                    var line = "  Similar: \(asset.displayName)"
                    
                    if verbose {
                        line += " (distance: \(String(format: "%.2f", distance)))"
                    }
                    
                    if asset.isUsed == false {
                        line += " - ⚠️ UNUSED"
                    }
                    
                    print(line)
                }
                
                print("  Total size: \(formatBytes(totalSize))")
                print("  Potential savings: \(formatBytes(potentialSavings))")
                
                // If all assets in group are unused, highlight this
                let allUnused = group.allAssets.allSatisfy { $0.isUsed == false }
                if allUnused {
                    print("  💡 All assets in this group are unused - \(formatBytes(totalSize)) can be freed immediately!")
                }
                
                print()
            }
            
            let totalSavings = groups.reduce(0) { $0 + $1.potentialSavings }
            print("💡 Total potential savings from duplicates: \(formatBytes(totalSavings))")
        }
        
        // Unused assets section - only show if usage was checked
        let unusedAssets = allAssets.filter { $0.isUsed == false }
        if !unusedAssets.isEmpty {
            print("\n🗑️ Found \(unusedAssets.count) potentially unused asset(s):\n")
            
            // Group unused assets by whether they're in similarity groups
            let assetsInGroups = Set(groups.flatMap { $0.allAssets })
            let unusedInGroups = unusedAssets.filter { assetsInGroups.contains($0) }
            let unusedStandalone = unusedAssets.filter { !assetsInGroups.contains($0) }
            
            if !unusedStandalone.isEmpty {
                print("Unused standalone assets (safe to delete):")
                for asset in unusedStandalone.sorted(by: { $0.displayName < $1.displayName }) {
                    print("  • \(asset.displayName) (\(formatBytes(asset.fileSize)))")
                }
                
                let standaloneSize = unusedStandalone.reduce(0) { $0 + $1.fileSize }
                print("  Total: \(formatBytes(standaloneSize))")
            }
            
            if !unusedInGroups.isEmpty && verbose {
                print("\nUnused assets that have duplicates (see groups above):")
                for asset in unusedInGroups.sorted(by: { $0.displayName < $1.displayName }) {
                    print("  • \(asset.displayName)")
                }
            }
            
            let totalUnusedSize = unusedAssets.reduce(0) { $0 + $1.fileSize }
            print("\n🎯 Total space used by unused assets: \(formatBytes(totalUnusedSize))")
        }
    }
    
    private func outputJSON(groups: [SimilarityGroup], allAssets: [ImageAsset], from baseURL: URL) {
        var output: [String: Any] = [:]
        
        // Similar groups
        output["similarGroups"] = groups.map { group in
            [
                "primary": [
                    "name": group.primary.displayName,
                    "path": formatAssetPath(group.primary, from: baseURL),
                    "unused": group.primary.isUsed == false
                ],
                "similar": group.similar.map { asset, distance in
                    [
                        "name": asset.displayName,
                        "path": formatAssetPath(asset, from: baseURL),
                        "distance": distance,
                        "unused": asset.isUsed == false
                    ]
                },
                "totalSize": group.totalSize,
                "potentialSavings": group.potentialSavings,
                "allUnused": group.allAssets.allSatisfy { $0.isUsed == false }
            ]
        }
        
        // Unused assets (only if usage was checked)
        let unusedAssets = allAssets.filter { $0.isUsed == false }
        if !unusedAssets.isEmpty {
            output["unusedAssets"] = unusedAssets.map { asset in
                [
                    "name": asset.displayName,
                    "path": formatAssetPath(asset, from: baseURL),
                    "size": asset.fileSize
                ]
            }
        }
        
        // Summary
        let totalDuplicateSavings = groups.reduce(0) { $0 + $1.potentialSavings }
        let totalUnusedSize = unusedAssets.reduce(0) { $0 + $1.fileSize }
        let usageChecked = allAssets.first?.isUsed != nil
        
        output["summary"] = [
            "totalGroups": groups.count,
            "totalUnused": unusedAssets.count,
            "duplicateSavings": totalDuplicateSavings,
            "unusedSize": totalUnusedSize,
            "totalPotentialSavings": totalDuplicateSavings + totalUnusedSize,
            "usageChecked": usageChecked
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    }
    
    private func outputXcode(groups: [SimilarityGroup], allAssets: [ImageAsset], from baseURL: URL) {
        // Output similar assets warnings
        for group in groups {
            let primaryPath = group.primary.url.path
            let unusedTag = group.primary.isUsed == false ? " [UNUSED]" : ""
            print("warning: \(primaryPath):1:1: Similar assets detected - \(group.primary.displayName)\(unusedTag)")
            
            for (asset, _) in group.similar {
                let assetUnusedTag = asset.isUsed == false ? " [UNUSED]" : ""
                print("note: \(asset.url.path):1:1: Similar to \(group.primary.displayName)\(assetUnusedTag)")
            }
        }
        
        // Output unused assets warnings (only if usage was checked)
        let unusedAssets = allAssets.filter { $0.isUsed == false }
        for asset in unusedAssets {
            print("warning: \(asset.url.path):1:1: Potentially unused asset - \(asset.displayName)")
        }
        
        // Summary
        if !groups.isEmpty || !unusedAssets.isEmpty {
            let totalSavings = groups.reduce(0) { $0 + $1.potentialSavings }
            let unusedSize = unusedAssets.reduce(0) { $0 + $1.fileSize }
            print("warning: Found \(groups.count) groups of similar assets (\(formatBytes(totalSavings))) and \(unusedAssets.count) unused assets (\(formatBytes(unusedSize)))")
        }
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
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
