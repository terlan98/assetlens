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
    @Published var selectedGroup: SimilarityGroup?
    
    var unusedGroupsCount: Int {
        similarityGroups.count { $0.allUnused }
    }
    
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
    
    func deleteAllUnusedGroups() {
        similarityGroups.filter { $0.allUnused }.forEach { deleteAll(in: $0) }
    }
    
    func deleteAll(in group: SimilarityGroup) {
        for asset in group.allAssets {
            deleteImageSet(of: asset)
        }
        
        withAnimation {
            similarityGroups.removeAll { $0 == group }
        }
    }
    
    /// Deletes the imageset corresponding to the given asset and marks it as deleted
    func deleteImageSet(of asset: ImageAsset) {
        do {
            let urlDeletingLastComponent = asset.url.deletingLastPathComponent()
            let isImageSetUrlFound = urlDeletingLastComponent.lastPathComponent.hasSuffix("imageset")
            
            if isImageSetUrlFound,
               let indexOfGroupContainingAsset = similarityGroups.firstIndex(where: { $0.allAssets.contains(asset) }) {
                try FileManager.default.trashItem(at: urlDeletingLastComponent, resultingItemURL: nil)
                
                var assetCopy = asset
                assetCopy.isDeleted = true
                
                let groupContainingAsset = similarityGroups[indexOfGroupContainingAsset]
                
                withAnimation {
                    if groupContainingAsset.primary == asset { // deleted primary
                        similarityGroups[indexOfGroupContainingAsset].primary = assetCopy
                    } else if let indexOfSimilarInGroup = groupContainingAsset.similar.firstIndex(where: { $0.0 == asset }) { // deleted non-primary
                        let existingDistance = similarityGroups[indexOfGroupContainingAsset].similar[indexOfSimilarInGroup].1
                        similarityGroups[indexOfGroupContainingAsset].similar[indexOfSimilarInGroup] = (assetCopy, existingDistance)
                    }
                    
                    if selectedGroup == groupContainingAsset {
                        selectedGroup = similarityGroups[indexOfGroupContainingAsset]
                    }
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
