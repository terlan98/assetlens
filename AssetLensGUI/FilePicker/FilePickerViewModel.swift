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
    
    private var selectedPath: String?
    
    // MARK: - Drag and Drop
    
    func handleDrop(_ url: URL) {
        processSelectedFile(url)
    }
    
    // MARK: - File Processing
    
    private func processSelectedFile(_ url: URL) {
        let path = url.path
        
        if url.hasDirectoryPath, assetsExist(at: url) {
            selectedPath = path
            errorMessage = nil
            Router.shared.push(Route.analysis(viewModel: .init(selectedPath: path)))
            print("Selected directory: \(path)")
        } else {
            errorMessage = "Selected folder doesn't contain an Xcode project"
            selectedPath = nil
        }
    }
    
    private func assetsExist(at url: URL) -> Bool {
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
