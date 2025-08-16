//
//  FilePickerViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FilePickerViewModel: ObservableObject {
    @Published var selectedPath: String?
    @Published var isDragOver = false
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    // Computed property for UI display
    var selectedProjectName: String? {
        guard let path = selectedPath else { return nil }
        return URL(fileURLWithPath: path).lastPathComponent
    }
    
    var canAnalyze: Bool {
        selectedPath != nil && !isAnalyzing
    }
    
    // MARK: - File Selection
    
    func selectFile() {
        let panel = NSOpenPanel()
        panel.title = "Select Xcode Project"
        panel.message = "Choose your .xcodeproj or .xcworkspace file"
        panel.prompt = "Select"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            UTType(filenameExtension: "xcodeproj") ?? .folder,
            UTType(filenameExtension: "xcworkspace") ?? .folder
        ]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                processSelectedFile(url)
            }
        }
    }
    
    // MARK: - Drag and Drop
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                self.processSelectedFile(url)
            }
        }
        
        return true
    }
    
    // MARK: - File Processing
    
    private func processSelectedFile(_ url: URL) {
        let path = url.path
        let filename = url.lastPathComponent
        
        // Check if it's a valid Xcode project or workspace
        if filename.hasSuffix(".xcodeproj") || filename.hasSuffix(".xcworkspace") {
            // Get the parent directory for analysis
            let projectDirectory = url.deletingLastPathComponent().path
            selectedPath = projectDirectory
            errorMessage = nil
            print("Selected directory for analysis: \(projectDirectory)")
        } else if url.hasDirectoryPath {
            // User selected a directory - check if it contains a project
            if directoryContainsXcodeProject(at: url) {
                selectedPath = path
                errorMessage = nil
                print("Selected directory: \(path)")
            } else {
                errorMessage = "Selected folder doesn't contain an Xcode project"
                selectedPath = nil
            }
        } else {
            errorMessage = "Please select an Xcode project or workspace"
            selectedPath = nil
        }
    }
    
    private func directoryContainsXcodeProject(at url: URL) -> Bool {
        let fileManager = FileManager.default
        let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        return contents?.contains { fileURL in
            let name = fileURL.lastPathComponent
            return name.hasSuffix(".xcodeproj") ||
                   name.hasSuffix(".xcworkspace") ||
                   name.hasSuffix(".xcassets")
        } ?? false
    }
    
    // MARK: - Analysis
    
    func analyzeProject() {
        guard let path = selectedPath else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        // Simulate analysis for now
        print("Starting analysis of project at: \(path)")
        
        // TODO: Replace with actual AssetLensCore call
        Task {
            do {
                // Simulated delay
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // let analyzer = AssetLensCore(path: path)
                // let results = try await analyzer.analyze()
                // self.handleResults(results)
                
                print("Analysis complete for: \(path)")
                isAnalyzing = false
            } catch {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }
    
    func clearSelection() {
        selectedPath = nil
        errorMessage = nil
        isAnalyzing = false
    }
}
