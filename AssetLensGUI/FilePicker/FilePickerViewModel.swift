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
        UTType.folder
    ]
    
    private var selectedPath: String?
    
    // MARK: - Drag and Drop
    func handleDrop(_ url: URL) {
        processSelectedFile(url, shouldAccessSecurityScope: false)
    }
    
    // MARK: - File Selection
    
    func didTapSelectFile() {
        shouldShowFilePicker = true
    }
    
    func handleFileSelectionResult(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let fileUrl):
            guard fileUrl.startAccessingSecurityScopedResource() else {
                print("Failed to access security scope of URL: \(fileUrl)")
                return
            }
            
            processSelectedFile(fileUrl, shouldAccessSecurityScope: true)
        case .failure(let error):
            errorMessage = "Failed to select file"
            print("Failed to select file: \(error)")
        }
    }
    
    // MARK: - File Processing
    
    private func processSelectedFile(_ url: URL, shouldAccessSecurityScope: Bool) {
        guard !shouldAccessSecurityScope || url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scope of URL: \(url)")
            return
        }
        
        let path = url.path
        
        if url.hasDirectoryPath, assetsExist(at: url, shouldAccessSecurityScope: shouldAccessSecurityScope) {
            selectedPath = path
            errorMessage = nil
            Router.shared.push(Route.analysis(viewModel: .init(selectedPath: path)))
            print("Selected directory: \(path)")
        } else {
            errorMessage = "Selected folder doesn't contain an Xcode project"
            selectedPath = nil
        }
    }
    
    private func assetsExist(at url: URL, shouldAccessSecurityScope: Bool) -> Bool {
        guard !shouldAccessSecurityScope || url.startAccessingSecurityScopedResource() else {
            print("Failed to access security scope of URL: \(url)")
            return false
        }
        
        defer {
            if shouldAccessSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: { url, error in
                print("Error while enumerating files: \(error)")
                return false
            }
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent.contains(".xcassets") {
                    return true
                }
            }
        }
        
        return false
    }
}
