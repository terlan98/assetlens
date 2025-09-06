//
//  InfoBoxModifier.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 06.09.25.
//

import SwiftUI

struct InfoBox: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.orange.opacity(0.1))
            .clipShape(.rect(cornerRadius: 4))
    }
}

extension View {
    func infoBox() -> some View {
        modifier(InfoBox())
    }
}
