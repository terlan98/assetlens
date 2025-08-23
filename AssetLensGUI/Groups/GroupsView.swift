//
//  GroupsView.swift
//  AssetLensGUI
//
//  Created by Tarlan Ismayilsoy on 22.08.25.
//

import SwiftUI
import AssetLensCore

struct GroupsView: View {
    private enum Constants {
        static let imageSize: CGFloat = 75
        static let groupMinWidth: CGFloat = 100
        static let groupCornerRadius: CGFloat = 14
        static let groupPadding: CGFloat = 10
    }
    
    @StateObject private var viewModel: GroupsViewModel
    
    init(_ viewModel: @escaping @autoclosure (() -> GroupsViewModel)) {
        _viewModel = .init(wrappedValue: viewModel())
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: Constants.groupMinWidth), spacing: 20, alignment: .top)
                ],
                alignment: .leading,
                spacing: 20
            ) {
                ForEach(Array(viewModel.similarityGroups.enumerated()), id: \.element) { index, group in
                    VStack(spacing: 14) {
                        VStack(spacing: .zero) {
                            Text("GROUP #\(index + 1)")
                                .font(.footnote)
                                .bold()
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(group.totalSize.formattedAsBytes())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        AsyncImage(url: group.primary.url) { asyncImageResult in // TODO: fix PDF rendering
                            asyncImageResult.image?
                                .resizable()
                                .scaledToFit()
                                .clipShape(.rect(cornerRadius: Constants.groupCornerRadius - Constants.groupPadding))
                        }
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        
                        Text("\(group.similar.count) similar assets")
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .font(.caption)
                        
                        if group.unusedAssets.count > 0 {
                            unusedAssetsText(for: group)
                        }
                        
                        if group.allUnused {
                            deleteAllButton(for: group)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Constants.groupPadding)
                    .fixedSize()
                    .background {
                        RoundedRectangle(cornerRadius: Constants.groupCornerRadius)
                            .fill(backgroundColor(for: group))
                            .stroke(strokeColor(for: group), lineWidth: 1)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func strokeColor(for group: SimilarityGroup) -> Color {
        group.allUnused ? .orange.opacity(0.25) : .primary.opacity(0.25)
    }
    
    private func backgroundColor(for group: SimilarityGroup) -> Color {
        group.allUnused ? .orange.opacity(0.1) : Color.secondary.opacity(0.2)
    }
    
    private func unusedAssetsText(for group: SimilarityGroup) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(group.unusedAssets.count.description)
                .bold()
                .font(.body)
                .foregroundStyle(.orange)
            
            Text("unused")
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.orange)
        }
    }
    
    private func deleteAllButton(for group: SimilarityGroup) -> some View {
        Button {
            print("TODO")
        } label: {
            Label("Delete all", systemImage: "trash.fill")
                .textCase(.uppercase)
                .font(.caption)
                .padding(8)
                .foregroundStyle(.red)
                .background(.red.opacity(0.2))
                .clipShape(.rect(cornerRadius: Constants.groupCornerRadius / 2))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let mockImageUrl = Bundle.main.url(forResource: "mock_icon", withExtension: "png")!
    
    GroupsView(
        .init(similarityGroups: (1...20).map { _ in
            SimilarityGroup(
                primary: ImageAsset(url: mockImageUrl, isUsed: Bool.random()), similar: (1...Int.random(in: 2...5)).map { _ in
                    (ImageAsset(url: mockImageUrl, isUsed: Bool.random()), Float.random(in: 0...1))
                }
            )
        })
    )
    .frame(width: 600, height: 700)
}
