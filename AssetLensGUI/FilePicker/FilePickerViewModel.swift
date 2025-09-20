//
//  FilePickerViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import OSLog
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FilePickerViewModel: ObservableObject {
    @Published var isDragOver = false
    @Published var errorMessage: String? {
        didSet { resetErrorMessageAfterDelay() }
    }
    
    private var selectedPath: String?
    private var errorResetTask: Task<Void, Never>?
    private lazy var logger = Logger(for: Self.self)
    
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
            
            logger.info("Selected directory: \(path)")
        } else {
            errorMessage = "Selected folder doesn't contain an Xcode project"
            selectedPath = nil
            
            logger.warning("No Xcode project found in \(path)")
        }
    }
    
    private func assetsExist(at url: URL) -> Bool {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles],
            errorHandler: { [weak self] url, error in
                self?.logger.error("Error while enumerating files: \(error)")
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
    
    private func resetErrorMessageAfterDelay() {
        guard errorMessage != nil else { return }
        errorResetTask?.cancel()
        
        errorResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            
            if !Task.isCancelled {
                self?.errorMessage = nil
            }
        }
    }
}
