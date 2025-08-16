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
        Text("Hello, World!")
    }
}

#Preview {
    AnalysisView(.init(selectedPath: ""))
}
