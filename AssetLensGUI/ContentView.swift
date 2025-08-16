//
//  ContentView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 16.08.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        FilePickerView()
            .frame(minWidth: 400, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
