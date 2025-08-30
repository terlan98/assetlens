//
//  GroupDetailView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 23.08.25.
//

import SwiftUI
import AssetLensCore

struct GroupDetailView: View {
    private enum Constants {
        static let imageSize: CGFloat = 100
        static let rowCornerRadius: CGFloat = 14
    }
    
    @Environment(\.dismiss) private var dismiss
    let group: SimilarityGroup
    
    var body: some View {
        VStack {
            closeButton
            
            ScrollView {
                VStack {
                    assetInfoView(for: group.primary)
                        .background(.secondary.opacity(0.15))
                        .clipShape(.rect(cornerRadius: Constants.rowCornerRadius))
                    
                    ForEach(group.similar, id: \.0) { assetAndDistance in
                        let asset = assetAndDistance.0
                        let distance = assetAndDistance.1
                        
                        assetInfoView(for: asset, distance)
                            .background(.tertiary.opacity(0.15))
                            .clipShape(.rect(cornerRadius: Constants.rowCornerRadius))
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
    }
    
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .padding([.bottom, .leading], 10)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // TODO: add delete button
    private func assetInfoView(for asset: ImageAsset, _ distance: Float? = nil) -> some View {
        HStack(spacing: 14) {
            VStack {
                AssetImageView(asset: asset, size: Constants.imageSize)
                Text(asset.fileSize.formattedAsBytes())
            }
            
            VStack(alignment: .leading) {
                Text("NAME")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(asset.displayName)
            }
            
            Spacer()
            
            if asset.isUsed == false {
                usageLabel
            }
        }
        .overlay(alignment: .topTrailing) {
            finderButton(for: asset)
        }
        .padding()
    }
    
    private var usageLabel: some View {
        Text("NOT USED")
            .font(.caption)
            .bold()
            .padding(4)
            .background(.secondary)
            .foregroundStyle(.orange)
            .clipShape(.rect(cornerRadius: 6))
    }
    
    private func finderButton(for asset: ImageAsset) -> some View {
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([asset.url.deletingLastPathComponent()])
        } label: {
            Image(systemName: "folder.fill")
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let mockImageUrl = Bundle.main.url(forResource: "mock_icon", withExtension: "png")!
    
    GroupDetailView(
        group:
            SimilarityGroup(
                primary: ImageAsset(url: mockImageUrl, isUsed: Bool.random()),
                similar: (1...Int.random(in: 1...5)).map { _ in
                    (ImageAsset(url: mockImageUrl, isUsed: Bool.random()), Float.random(in: 0...1))
                }
            )
    )
}
