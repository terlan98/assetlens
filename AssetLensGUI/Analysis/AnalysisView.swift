//
//  AnalysisView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

struct AnalysisView: View {
    @StateObject private var viewModel: AnalysisViewModel

    private let cornerRadius: CGFloat = 12
    
    init(_ viewModel: @escaping @autoclosure (() -> AnalysisViewModel)) {
        _viewModel = .init(wrappedValue: viewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                appIconSection
                
                if !viewModel.isAnalyzing {
                    settingsSection
                }
            }
            .padding(20)
            .background(Color.gray.opacity(0.05))
            .clipShape(
                .rect(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: viewModel.isAnalyzing ? cornerRadius : 0,
                    bottomTrailingRadius: viewModel.isAnalyzing ? cornerRadius : 0,
                    topTrailingRadius: cornerRadius
                )
            )
            
            if !viewModel.isAnalyzing {
                analyzeButton
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: viewModel.isAnalyzing)
        .onAppear {
            viewModel.loadAppIcon()
        }
        .navigationTitle("Analysis")
    }
    
    // MARK: - View Components
    
    private var appIconSection: some View {
        VStack(spacing: 20) {
            Group {
                if let appIcon = viewModel.appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(20)
                        .shadow(radius: 10)
                } else { // Placeholder
                    Image(systemName: "app.dashed")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .overlay {
                if viewModel.isAnalyzing {
                    analysisOverlay
                }
            }
            
            if viewModel.isAnalyzing {
                analysisProgressView
            }
        }
        .frame(maxWidth: 200)
    }
    
    private var analysisOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray.opacity(0.2))
        }
    }
    
    private var analysisProgressView: some View {
        ProgressView {
            Text("Analyzing...")
        }
        .progressViewStyle(.linear)
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
            .clipShape(.rect(cornerRadius: cornerRadius))
            .frame(minWidth: 300)
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            viewModel.startAnalysis()
        }) {
            HStack {
                Spacer()
                
                Text("Start Analysis")
                    .font(.title2)
                
                Image(systemName: "chevron.right.2")
                    .symbolEffect(.pulse, options: .speed(1.8))
                    .font(.system(size: 24))
                    .bold()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(Color.accentColor.opacity(0.8))
            .clipShape(.rect(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AnalysisView(.init(selectedPath: "/Users/Example/MyProject"))
        .frame(width: 600, height: 700)
}
