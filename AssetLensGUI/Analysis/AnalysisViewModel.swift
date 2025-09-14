//
//  AnalysisViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI
import AppKit
import AssetLensCore
import OSLog

@MainActor
class AnalysisViewModel: ObservableObject {
    let selectedPath: String
    
    @Published var appIcon: NSImage?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var analysisProgressMessage: String?
    @Published var isAlertShown = false
    
    // Settings
    @AppStorage("analysisThreshold") var threshold: Double = 0.5
    @AppStorage("analysisMinFileSize") var minFileSize: Int = 1
    @AppStorage("analysisShouldCheckUsage") var shouldCheckUsage = true
    
    private lazy var logger = Logger(for: Self.self)
    
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
            logger.error("Error loading app icon: \(error)")
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
        
        logger.info(
            """
            Starting analysis...
            Path: \(self.selectedPath)
            Threshold: \(self.threshold)
            Min file size: \(self.minFileSize) KB
            Check usage: \(self.shouldCheckUsage)
            """
        )
        
        let shouldCheckUsage = self.shouldCheckUsage
        
        Task { [weak self] in
            guard let self else { return }
            
            do {                
                await asyncProgressUpdate("Scanning for assets...")
                
                var assets = try await scanner.scanDirectory(at: url, minSizeKB: self.minFileSize)
                
                guard !assets.isEmpty else {
                    logger.error("No image assets found at \(url.path)")
                    await finalizeAnalysis(with: "No assets found in project")
                    return
                }
                
                logger.info("Found \(assets.count) assets to analyze")
                
                var unusedAssets: Set<ImageAsset> = []
                if shouldCheckUsage {
                    await asyncProgressUpdate("Checking usages of ^[\(assets.count) assets](inflect: true)")
                    
                    let usageAnalyzer = UsageAnalyzer()
                    unusedAssets = await usageAnalyzer.findUnusedAssets(assets: assets, in: url, verbosity: .normal)
                    
                    // Update isUsed for ALL assets
                    for i in assets.indices {
                        assets[i].isUsed = !unusedAssets.contains(assets[i])
                    }
                }
                
                // Analyze similarities
                let groups = try await analyzer.findSimilarGroups(in: assets) { progress in
                    Task { [weak self] in
                        let formattedProgress = progress.formatted(.percent.precision(.fractionLength(0)))
                        await self?.asyncProgressUpdate("Analyzing similarities (\(formattedProgress))...")
                    }
                }
                
                await finalizeAnalysis()
                Router.shared.push(
                    Route.groups(
                        viewModel: .init(
                            similarityGroups: groups,
                            usedSettings: currentSettings
                        )
                    )
                )
            } catch {
                await finalizeAnalysis(with: error.localizedDescription)
            }
        }
    }
    
    private func finalizeAnalysis(with errorMessage: String? = nil) async {
        await MainActor.run {
            self.isAnalyzing = false
            self.analysisProgressMessage = nil
            self.errorMessage = errorMessage
            self.isAlertShown = (errorMessage != nil)
        }
    }
    
    private func asyncProgressUpdate(_ message: String) async {
        await MainActor.run {
            self.analysisProgressMessage = message
        }
    }
}

struct AnalysisSettings {
    let threshold: Double
    let minFileSize: Int
    let shouldCheckUsage: Bool
}

extension AnalysisViewModel {
    private var currentSettings: AnalysisSettings {
        .init(threshold: self.threshold, minFileSize: self.minFileSize, shouldCheckUsage: self.shouldCheckUsage)
    }
}
