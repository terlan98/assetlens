//
//  SimilarityGroup.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

struct SimilarityGroup {
    var primary: ImageAsset
    var similar: [(ImageAsset, Float)]
    
    /// All assets in the group (primary + similar)
    var allAssets: [ImageAsset] {
        [primary] + similar.map { $0.0 }
    }
    
    var totalSize: Int64 {
        primary.fileSize + similar.reduce(0) { $0 + $1.0.fileSize }
    }
    
    var potentialSavings: Int64 {
        if allAssets.allSatisfy({ $0.isUsed == false }) {
            return totalSize
        } else {
            let smallestAssetSize = allAssets.map { $0.fileSize }.min() ?? 0
            return totalSize - smallestAssetSize
        }
    }
}
