//
//  VerbosityLevel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 13.08.25.
//

import Foundation
import ArgumentParser

enum VerbosityLevel: String, ExpressibleByArgument, CaseIterable, Comparable {
    case normal
    case verbose
    case debug
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        let order = Self.allCases
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
