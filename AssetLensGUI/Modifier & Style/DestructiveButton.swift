//
//  DestructiveButton.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 06.09.25.
//

import SwiftUI

struct DestructiveButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textCase(.uppercase)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foregroundStyle(.red)
            .background(.red.opacity(0.2))
            .clipShape(.rect(cornerRadius: 7))
    }
}

extension ButtonStyle where Self == DestructiveButton {
    static var customDestructive: DestructiveButton { .init() }
}
