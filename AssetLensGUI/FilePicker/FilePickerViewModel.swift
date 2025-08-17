//
//  FilePickerViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FilePickerViewModel: ObservableObject { // TODO: replace prints with logs
    @Published var isDragOver = false
    @Published var errorMessage: String?
    @Published var shouldShowFilePicker = false
    
    let allowedContentTypes = [
        UTType(tag: "xcodeproj", tagClass: .filenameExtension, conformingTo: .compositeContent) ?? .folder,
        UTType(tag: "xcworkspace", tagClass: .filenameExtension, conformingTo: .compositeContent) ?? .folder,
    ]
    
    private var selectedPath: String?
    
    // MARK: - File Selection
    
    func didTapSelectFile() {
        shouldShowFilePicker = true
    }
    
    func handleFileSelectionResult(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let fileUrl):
            processSelectedFile(fileUrl)
        case .failure(let error):
            errorMessage = "Failed to select file"
            print("Failed to select file: \(error)")
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
            Router.shared.push(Route.analysis(viewModel: .init(selectedPath: projectDirectory)))
            print("Selected directory for analysis: \(projectDirectory)")
        } else if url.hasDirectoryPath {
            // User selected a directory - check if it contains a project
            if directoryContainsXcodeProject(at: url) {
                selectedPath = path
                errorMessage = nil
                Router.shared.push(Route.analysis(viewModel: .init(selectedPath: path)))
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
}
