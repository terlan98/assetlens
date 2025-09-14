//
//  LoggerExt.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 14.09.25.
//

import OSLog

extension Logger {
    private static var sharedSubsystem: String {
        Bundle.main.bundleIdentifier ?? "AssetLens"
    }
    
    init<T>(for type: T.Type) {
        self.init(
            subsystem: Self.sharedSubsystem,
            category: String(describing: type)
        )
    }
}
