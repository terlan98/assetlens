//
//  GroupsViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 22.08.25.
//

import SwiftUI
import AssetLensCore

@MainActor
class GroupsViewModel: ObservableObject {
    let similarityGroups: [SimilarityGroup]
    
    init(similarityGroups: [SimilarityGroup]) {
        self.similarityGroups = similarityGroups
    }
}
