//
//  GroupsViewModel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 22.08.25.
//

import OSLog
import SwiftUI
import AssetLensCore

@MainActor
class GroupsViewModel: ObservableObject {
    @Published var currentSortingCriterion: GroupSortingCriterion = .unusedFirst
    @Published var similarityGroups: [SimilarityGroup]
    @Published var selectedGroup: SimilarityGroup?
    @Published var errorMessage: String? // TODO: Tarlan - reset after 3 seconds
    
    var usedSettings: AnalysisSettings
    
    var unusedGroupsCount: Int {
        similarityGroups.count { $0.allUnused }
    }
    
    private lazy var logger = Logger(for: Self.self)
    
    init(similarityGroups: [SimilarityGroup], usedSettings: AnalysisSettings) {
        self.similarityGroups = similarityGroups
        self.usedSettings = usedSettings
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
    
    func delete(_ selection: DeleteSelection) {
        switch selection {
        case .asset(let asset):
            deleteImageSet(of: asset)
        case .group(let group):
            deleteAll(in: group)
        }
    }
    
    func deleteAllUnusedGroups() {
        similarityGroups.filter { $0.allUnused }.forEach { deleteAll(in: $0) }
    }
    
    private func deleteAll(in group: SimilarityGroup) {
        // Dismiss selection if needed
        if selectedGroup == group {
            selectedGroup = nil
        }
        
        // Delete files
        for asset in group.allAssets {
            deleteImageSet(of: asset)
        }
        
        // Update UI
        withAnimation {
            similarityGroups.removeAll { $0 == group }
        }
    }
    
    /// Deletes the imageset corresponding to the given asset and marks it as deleted
    private func deleteImageSet(of asset: ImageAsset) {
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
                errorMessage = "Could not find the image set for \(asset.displayName)"
                logger.error("Could not find imageset to delete for \(asset.displayName)")
                selectedGroup = nil
            }
        } catch {
            errorMessage = "Could not delete image set for \(asset.displayName)"
            logger.error("Could not delete \(asset.displayName): \(error)")
            selectedGroup = nil
        }
    }
}

enum GroupSortingCriterion: CaseIterable {
    case sizeAscending
    case sizeDescending
    case usedFirst
    case unusedFirst
    case countAscending
    case countDescending
    
    var title: String {
        switch self {
        case .sizeAscending: "Smallest first (KB)"
        case .sizeDescending: "Largest first (KB)"
        case .usedFirst: "Used first"
        case .unusedFirst: "Unused first"
        case .countAscending: "Smallest first"
        case .countDescending: "Largest first"
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
        case .countAscending:
            group.sorted { $0[keyPath: \.similar.count] < $1[keyPath: \.similar.count] }
        case .countDescending:
            group.sorted { $0[keyPath: \.similar.count] > $1[keyPath: \.similar.count] }
        }
    }
}

enum DeleteSelection {
    case group(SimilarityGroup)
    case asset(ImageAsset)
}
