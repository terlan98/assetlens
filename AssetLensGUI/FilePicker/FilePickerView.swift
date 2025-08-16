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
        VStack(spacing: 20) {
            // Title Section
            headerSection
            
            // Drop Zone
            dropZoneSection
            
            // Selected Path Display
            if viewModel.selectedPath != nil {
                selectedPathSection
            }
            
            // Error Display
            if let error = viewModel.errorMessage {
                errorSection(error)
            }
            
            Spacer()
        }
        .padding(30)
        .frame(minWidth: 500, minHeight: 500)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
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
                .font(.system(size: 48))
                .foregroundColor(viewModel.isDragOver ? .accentColor : .secondary)
            
            Text("Drop your .xcodeproj or .xcworkspace here")
                .font(.headline)
            
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Browse Files") {
                viewModel.selectFile()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(80)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.isDragOver ? Color.accentColor.opacity(0.1) : .gray.opacity(0.05))
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundStyle(viewModel.isDragOver ? .accentColor : Color.secondary.opacity(0.5))
        }
        .onDrop(
            of: [.fileURL],
            isTargeted: $viewModel.isDragOver
        ) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }
    
    private var selectedPathSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Selected Project", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearSelection()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            Text(viewModel.selectedPath ?? "")
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                .textSelection(.enabled)
            
            Button(action: viewModel.analyzeProject) {
                if viewModel.isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing...")
                    }
                } else {
                    Text("Analyze")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.canAnalyze)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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
    }
}
