//
//  ContentView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var router = Router.shared
    
    var body: some View {
        NavigationStack(path: $router.path) {
            FilePickerView()
                .navigationDestination(for: Route.self, destination: router.destination(for:))
        }
    }
}

#Preview {
    ContentView()
}
