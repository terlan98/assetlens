//
//  AssetLensGUIApp.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

@main
struct AssetLensGUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
