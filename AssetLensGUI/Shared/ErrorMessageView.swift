//
//  ErrorMessageView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 20.09.25.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(.callout)
        .foregroundColor(.red)
        .padding(10)
        .background(Color.red.opacity(0.1))
        .clipShape(.rect(cornerRadius: 6))
    }
}

// MARK: - Preview

struct ErrorMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorMessageView(message: "This is an example error message")
            .padding()
    }
}
