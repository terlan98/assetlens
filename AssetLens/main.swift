//
//  main.swift
//  AssetLens - Find visually similar assets in Xcode projects
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation
import ArgumentParser

// MARK: - Command Line Interface
struct AssetLens: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "assetlens",
        abstract: "Find visually similar assets in Xcode projects",
        version: "1.0.0"
    )
    
    @Argument(help: "Path to Xcode project or .xcassets catalog")
    var projectPath: String
    
    @Option(name: .shortAndLong, help: "Similarity threshold (lower is more similar)")
    var threshold: Float = 0.5
    
    @Option(name: .shortAndLong, help: "Output format (text, json, xcode)")
    var format: OutputFormat = .text
    
    @Option(name: .shortAndLong, help: "Verbosity level (normal, verbose, debug)")
    var verbosity: VerbosityLevel = .normal
    
    @Flag(name: .long, help: "Exit with error code if duplicates found")
    var strict = false
    
    @Option(name: .long, help: "Minimum file size in KB to consider")
    var minSize: Int = 1
    
    @Flag(name: .shortAndLong, help: "Check for unused assets")
    var usageCheck = false
    
    mutating func run() throws {
        let scanner = AssetScanner()
        let analyzer = SimilarityAnalyzer(threshold: threshold)
        
        // Expand path
        let expandedPath = NSString(string: projectPath).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        // Scan for assets
        if format == .xcode {
            print("note: Scanning \(url.lastPathComponent) for similar assets...")
        } else if verbosity == .normal {
            print("Scanning \(url.path)...")
        }
        
        var assets = try scanner.scanDirectory(at: url, minSizeKB: minSize)
        
        guard !assets.isEmpty else {
            print("No image assets found at \(url.path)")
            throw ExitCode.failure
        }
        
        if verbosity >= .verbose && format != .xcode {
            print("Found \(assets.count) assets to analyze")
        }
        
        // Check for unused assets if requested
        var unusedAssets: Set<ImageAsset> = []
        if usageCheck {
            let usageAnalyzer = UsageAnalyzer()
            unusedAssets = usageAnalyzer.findUnusedAssets(assets: assets, in: url, verbosity: verbosity)
            
            // Update isUsed for ALL assets
            for i in assets.indices {
                assets[i].isUsed = !unusedAssets.contains(assets[i])  // Fixed: NOT operator added
            }
        }
        
        // Analyze similarities - assets now have isUsed already set
        let groups = try analyzer.findSimilarGroups(in: assets, verbosity: verbosity)
        
        // Output results
        let formatter = OutputFormatter(format: format, verbosity: verbosity)
        formatter.output(groups: groups, allAssets: assets, from: url)
        
        // Exit code for CI/CD integration
        if strict && !groups.isEmpty {
            throw ExitCode(1)
        }
    }
}

// MARK: - Main Entry Point
AssetLens.main()
