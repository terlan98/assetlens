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
    
    var totalSize: Int64 {
        primary.fileSize + similar.reduce(0) { $0 + $1.0.fileSize }
    }
    
    var potentialSavings: Int64 {
        similar.reduce(0) { $0 + $1.0.fileSize }
    }
}
