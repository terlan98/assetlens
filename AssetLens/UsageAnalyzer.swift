//
//  UsageAnalyzer.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

class UsageAnalyzer { // TODO: make async
    func findUnusedAssets(assets: [ImageAsset], in projectURL: URL, verbose: Bool = false) -> Set<ImageAsset> {
        guard !assets.isEmpty else { return [] }
        
        if verbose {
            print("Checking usage of \(assets.count) assets...")
        }
        
        let allAssets = Set(assets)
        let unusedAssets = findUnusedAssets(from: allAssets, in: projectURL, verbose: verbose)
        
        if verbose {
            print("Found \(unusedAssets.count) potentially unused assets")
        }
        
        return unusedAssets
    }
    
    private func findUnusedAssets(from assets: Set<ImageAsset>, in projectURL: URL, verbose: Bool) -> Set<ImageAsset> {
        let projectPath = projectURL.path
        
        let escapedNames = assets.map { NSRegularExpression.escapedPattern(for: $0.displayName) }
        let pattern = escapedNames.joined(separator: "|")
        
        // -r: recursive
        // -h: no filenames
        // -o: only matches
        // -I: ignore binary files
        // -E: extended regex (for | operator)
        let command = """
                    grep --include="*.swift" --include="*.m" --include="*.h" \
                    --include="*.storyboard" --include="*.xib" --include="*.plist" \
                    --exclude-dir=".git" --exclude-dir="Build" \
                    --exclude-dir="Pods" --exclude-dir="Carthage" \
                    -rhoI -E '\(pattern)' '\(projectPath)' | sort -u
                    """
        
        let result = shell(command)
        
        // Parse the output to get used asset names
        let usedNames = result.output
            .split(separator: "\n")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        if verbose && !usedNames.isEmpty {
            print("Found \(usedNames.count) assets referenced in code")
        }
        
        return assets.filter { !usedNames.contains($0.displayName) }
    }
    
    @discardableResult
    private func shell(_ command: String) -> (output: String, exitCode: Int32) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = Pipe()  // discard stderr
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.standardInput = nil
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            return (output, task.terminationStatus)
        } catch {
            return ("", -1)
        }
    }
}

// Make ImageAsset Hashable for Set operations
extension ImageAsset: Hashable {
    static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
