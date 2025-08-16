//
//  AnalysisViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

@MainActor
class AnalysisViewModel: ObservableObject { // TODO: replace prints with logs
    var selectedPath: String?
    
    init(selectedPath: String) {
        self.selectedPath = selectedPath
    }
}
