//
//  OutputFormat.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 13.08.25.
//

import Foundation
import ArgumentParser

enum OutputFormat: String, ExpressibleByArgument {
    case text, json, xcode
}
