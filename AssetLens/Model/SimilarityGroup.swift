//
//  SimilarityGroup.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

struct SimilarityGroup {
    let primary: ImageAsset
    let similar: [(ImageAsset, Float)]
    
    /// All assets in the group (primary + similar)
    var allAssets: [ImageAsset] {
        [primary] + similar.map { $0.0 }
    }
    
    var totalSize: Int64 {
        primary.fileSize + similar.reduce(0) { $0 + $1.0.fileSize }
    }
    
    var potentialSavings: Int64 {
        let totalSize = allAssets.reduce(0) { $0 + $1.fileSize }
        let smallestAssetSize = allAssets.map { $0.fileSize }.min() ?? 0
        return totalSize - smallestAssetSize
    }
}
