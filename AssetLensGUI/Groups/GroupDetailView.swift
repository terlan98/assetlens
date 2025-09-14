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
    typealias DeleteCallback = (DeleteSelection) -> Void
    
    let group: SimilarityGroup
    var onDelete: DeleteCallback?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            closeButton
            
            if group.allUnused {
                allUnusedInfoBox
            }
            
            ScrollView {
                VStack {
                    assetInfoView(for: group.primary)
                        .background(.secondary.opacity(0.15))
                        .clipShape(.rect(cornerRadius: Constants.rowCornerRadius))
                    
                    ForEach(group.similar, id: \.0) { assetAndDistance in
                        let asset = assetAndDistance.0
                        let distance = assetAndDistance.1
                        
                        assetInfoView(for: asset, distance: distance)
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
    
    private var allUnusedInfoBox: some View {
        HStack(spacing: 4) {
            Text("All assets in this group are unused")
                .foregroundStyle(.orange)
            
            Spacer()
            
            Button {
                onDelete?(.group(group))
            } label: {
                Label("DELETE GROUP", systemImage: "trash.fill")
            }
            .buttonStyle(.customDestructive)
        }
        .frame(maxWidth: .infinity)
        .infoBox()
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private func assetInfoView(for asset: ImageAsset, distance: Float? = nil) -> some View {
        if asset.isDeleted {
            deletedAssetInfoView(for: asset)
                .transition(.move(edge: .leading))
        } else {
            HStack(spacing: 14) {
                VStack {
                    AssetImageView(asset: asset, size: Constants.imageSize)
                    Text(asset.imageSetSize.formattedAsBytes())
                        .font(.callout)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("NAME")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(asset.displayName)
                            .font(.headline.monospaced())
                    }
                    
                    if let distance {
                        VStack(alignment: .leading) {
                            Text("DISTANCE")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text(distance.formatted(.number.precision(.fractionLength(2))))
                                .font(.headline.monospaced())
                        }
                    }
                }
                
                Spacer()
                
                if asset.isUsed == false {
                    usageLabel
                }
            }
            .contentShape(.rect)
            .onTapGesture(count: 2) {
                showInFinder(asset)
            }
            .overlay(alignment: .topTrailing) {
                buttons(for: asset)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func deletedAssetInfoView(for asset: ImageAsset) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "xmark.app")
                .resizable()
                .padding(8)
                .scaledToFit()
                .frame(width: Constants.imageSize, height: Constants.imageSize)
            
            VStack {
                Text("DELETED")
                    .font(.largeTitle)
                
                Text(asset.displayName)
                    .font(.caption.monospaced())
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .foregroundStyle(.secondary)
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
    
    private func buttons(for asset: ImageAsset) -> some View {
        HStack {
            deleteButton(for: asset)
            finderButton(for: asset)
        }
    }
    
    @ViewBuilder
    private func deleteButton(for asset: ImageAsset) -> some View {
        if asset.isUsed == false {
            Button {
                onDelete?(.asset(asset))
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title2)
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(maxHeight: 20)
        }
    }
    
    private func finderButton(for asset: ImageAsset) -> some View {
        Button {
            showInFinder(asset)
        } label: {
            Image(systemName: "folder.fill")
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
    
    private func showInFinder(_ asset: ImageAsset) {
        NSWorkspace.shared.activateFileViewerSelecting([asset.url.deletingLastPathComponent()])
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
