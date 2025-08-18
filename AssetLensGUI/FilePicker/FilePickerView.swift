//
//  FilePickerView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    @StateObject private var viewModel = FilePickerViewModel()
    
    var body: some View {
        VStack(spacing: 50) {
            headerSection
            dropZoneSection
            
            if let error = viewModel.errorMessage {
                errorSection(error)
            }
        }
        .padding(30)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(.filePickerIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text("AssetLens")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Analyze your Xcode project for duplicate and unused assets")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var dropZoneSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc.fill")
                .symbolEffect(.variableColor, options: .speed(0.35))
                .font(.system(size: 48))
                .foregroundColor(viewModel.isDragOver ? .accentColor : .secondary)
            
            Text("Drop your project folder here")
                .font(.footnote)
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
            
            Text("or")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
            
            Button("Browse Files") {
                viewModel.didTapSelectFile()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(80)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isDragOver ? Color.accentColor.opacity(0.1) : .gray.opacity(0.05))
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(viewModel.isDragOver ? .accentColor : Color.secondary.opacity(0.5))
        }
        .dropDestination(for: URL.self) { droppedUrls, _ in
            if let url = droppedUrls.first {
                viewModel.handleDrop(url)
                return true
            }
            return false
        } isTargeted: {
            viewModel.isDragOver = $0
        }
        .fileImporter(
            isPresented: $viewModel.shouldShowFilePicker,
            allowedContentTypes: viewModel.allowedContentTypes,
            onCompletion: viewModel.handleFileSelectionResult(_:)
        )
    }
    
    private func errorSection(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Preview

struct FilePickerView_Previews: PreviewProvider {
    static var previews: some View {
        FilePickerView()
            .frame(width: 500, height: 600)
    }
}
