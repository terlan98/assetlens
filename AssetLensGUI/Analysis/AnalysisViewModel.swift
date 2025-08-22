//
//  AnalysisViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI
import AppKit
import AssetLensCore

@MainActor
class AnalysisViewModel: ObservableObject { // TODO: replace prints with logs
    let selectedPath: String
    
    // UI State
    @Published var appIcon: NSImage?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    // Analysis Settings
    @Published var threshold: Double = 0.5
    @Published var minFileSize: Int = 1
    @Published var shouldCheckUsage = true
    
    init(selectedPath: String) {
        self.selectedPath = selectedPath
    }
    
    // MARK: - App Icon Loading
    
    func loadAppIcon() {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: selectedPath)
        
        // Try to find AppIcon.appiconset
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "AppIcon.appiconset" {
                    if let icon = loadIconFromAppIconSet(at: fileURL) {
                        self.appIcon = icon
                        return
                    }
                }
            }
        }
    }
    
    private func loadIconFromAppIconSet(at url: URL) -> NSImage? {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil
            )
            
            // Find the largest PNG file by filename pattern
            let pngFiles = contents.filter { $0.pathExtension.lowercased() == "png" }
            
            // Sort by expected size from filename (1024, 512, 256, etc.)
            let sortedIcons = pngFiles.sorted { first, second in
                let firstSize = extractSize(from: first.lastPathComponent)
                let secondSize = extractSize(from: second.lastPathComponent)
                return firstSize > secondSize
            }
            
            if let largestIcon = sortedIcons.first {
                return NSImage(contentsOf: largestIcon)
            }
        } catch {
            print("Error loading app icon: \(error)")
        }
        
        return nil
    }
    
    private func extractSize(from filename: String) -> Int {
        // Extract size from filenames like "icon_1024x1024.png" or "icon-1024.png"
        let numbers = filename.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 > 0 }
        
        return numbers.max() ?? 0
    }
    
    // MARK: - Analysis
    
    func startAnalysis() {
        isAnalyzing = true
        errorMessage = nil
        
        let url = URL(fileURLWithPath: selectedPath)
        let scanner = AssetScanner()
        let analyzer = SimilarityAnalyzer(threshold: Float(threshold))
        
        print("Starting analysis...")
        print("Path: \(selectedPath)")
        print("Threshold: \(threshold)")
        print("Min file size: \(minFileSize) KB")
        print("Check usage: \(shouldCheckUsage)")
        
        let shouldCheckUsage = self.shouldCheckUsage
        
        Task.detached(priority: .userInitiated) {
            do {
                // Simulate analysis delay
//                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                
                var assets = try await scanner.scanDirectory(at: url, minSizeKB: self.minFileSize)
                
                guard !assets.isEmpty else {
                    print("No image assets found at \(url.path)")
                    return
                }
                
                print("Found \(assets.count) assets to analyze")
                
                var unusedAssets: Set<ImageAsset> = []
                if shouldCheckUsage {
                    let usageAnalyzer = UsageAnalyzer()
                    unusedAssets = usageAnalyzer.findUnusedAssets(assets: assets, in: url, verbosity: .normal)
                    
                    // Update isUsed for ALL assets
                    for i in assets.indices {
                        assets[i].isUsed = !unusedAssets.contains(assets[i])
                    }
                }
                
                // Analyze similarities
                let groups = try analyzer.findSimilarGroups(in: assets, verbosity: .normal)
                
                dump(groups) // TODO: remove
                
                await MainActor.run {
                    self.isAnalyzing = false
                }
                
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
