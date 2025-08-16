//
//  AnalysisView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

struct AnalysisView: View {
    @StateObject private var viewModel: AnalysisViewModel

    init(_ viewModel: @escaping @autoclosure (() -> AnalysisViewModel)) {
        _viewModel = .init(wrappedValue: viewModel())
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                appIconSection
                
                if !viewModel.isAnalyzing {
                    settingsSection
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            if !viewModel.isAnalyzing {
                analyzeButton
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.loadAppIcon()
        }
    }
    
    // MARK: - View Components
    
    private var appIconSection: some View {
        ZStack {
            if let appIcon = viewModel.appIcon {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
//                    .frame(width: 128, height: 128)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            } else { // Placeholder
                Image(systemName: "app.dashed")
                    .font(.system(size: 128))
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isAnalyzing {
                analysisOverlay
            }
        }
        .frame(maxWidth: 200)
    }
    
    private var analysisOverlay: some View {
        ZStack {
            // Semi-transparent background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .frame(width: 128, height: 128)
            
            // Animated magnifying glass
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white)
                .symbolEffect(.pulse, options: .repeating)
//                .offset(x: viewModel.magnifyingGlassOffset.width,
//                       y: viewModel.magnifyingGlassOffset.height)
//                .animation(
//                    Animation.easeInOut(duration: 2)
//                        .repeatForever(autoreverses: true),
//                    value: viewModel.magnifyingGlassOffset
//                )
//                .onAppear {
//                    viewModel.startMagnifyingAnimation()
//                }
        }
    }
    
    private var settingsSection: some View {
        VStack {
            Text("Settings")
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                // Threshold
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Similarity Threshold", systemImage: "eye")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f", viewModel.threshold))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $viewModel.threshold, in: 0.1...2.0, step: 0.1)
                    
                    Text("Lower values find more similar images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Minimum File Size
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Minimum File Size", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        Text("Ignore files smaller than this size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .fixedSize()
                    
                    Spacer()
                    
                    TextField("Size (KB) ", value: $viewModel.minFileSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 60)
                    
                    Text("KB")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Usage Analysis
                Toggle(isOn: $viewModel.shouldCheckUsage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Check for Unused Assets", systemImage: "square.stack.3d.up.slash.fill")
                            .font(.headline)
                        Text("Scan code to find assets that aren't referenced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toggleStyle(.switch)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .frame(minWidth: 300)
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            viewModel.startAnalysis()
        }) {
            Label("Start Analysis", systemImage: "play.fill")
                .frame(maxWidth: 200)
        }
        .controlSize(.large)
        .buttonStyle(.borderless)
    }
}

#Preview {
    AnalysisView(.init(selectedPath: "/Users/Example/MyProject"))
        .frame(width: 600, height: 700)
}
