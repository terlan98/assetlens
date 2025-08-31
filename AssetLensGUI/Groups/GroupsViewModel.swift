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
    @Published var currentSortingCriterion: GroupSortingCriterion = .unusedFirst
    @Published var similarityGroups: [SimilarityGroup]
    
    init(similarityGroups: [SimilarityGroup]) {
        self.similarityGroups = similarityGroups
    }
    
    func setup() {
        similarityGroups = currentSortingCriterion.applied(to: similarityGroups)
    }
    
    func sortGroups(accordingTo criterion: GroupSortingCriterion) {
        guard criterion != currentSortingCriterion else { return }
        
        let sortedGroups = criterion.applied(to: similarityGroups)
        
        withAnimation {
            similarityGroups = sortedGroups
            currentSortingCriterion = criterion
        }
    }
    
    func deleteAll(in group: SimilarityGroup) {
        let primaryAssetUrl = group.primary.url
        
        do {
            let urlDeletingLastComponent = primaryAssetUrl.deletingLastPathComponent()
            let isImageSetUrlFound = urlDeletingLastComponent.lastPathComponent.hasSuffix("imageset")
            
            if isImageSetUrlFound {
                try FileManager.default.trashItem(at: urlDeletingLastComponent, resultingItemURL: nil)
                
                withAnimation {
                    similarityGroups.removeAll { $0 == group }
                }
            } else {
                print("Could not find imageset to delete") // TODO: show UI error
            }
        } catch {
            print("Could not delete item: \(error)") // TODO: show UI error
        }
    }
}

enum GroupSortingCriterion: CaseIterable {
    case sizeAscending
    case sizeDescending
    case usedFirst
    case unusedFirst
    
    var title: String {
        switch self {
        case .sizeAscending: "Smallest first"
        case .sizeDescending: "Largest first"
        case .usedFirst: "Used first"
        case .unusedFirst: "Unused first"
        }
    }
    
    func applied(to group: [SimilarityGroup]) -> [SimilarityGroup] {
        switch self {
        case .sizeAscending:
            group.sorted { $0[keyPath: \.totalSize] < $1[keyPath: \.totalSize] }
        case .sizeDescending:
            group.sorted { $0[keyPath: \.totalSize] > $1[keyPath: \.totalSize] }
        case .usedFirst:
            group.sorted { !$0.allUnused && $1.allUnused }
        case .unusedFirst:
            group.sorted { $0.allUnused && !$1.allUnused }
        }
    }
}
