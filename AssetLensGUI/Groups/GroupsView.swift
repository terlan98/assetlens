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
        static let settingsDividerHeight: CGFloat = 14
    }
    
    @StateObject private var viewModel: GroupsViewModel
    
    init(_ viewModel: @escaping @autoclosure (() -> GroupsViewModel)) {
        _viewModel = .init(wrappedValue: viewModel())
    }
    
    var body: some View { // TODO: handle 0 groups case
        VStack(spacing: 8) {
            HStack {
                title
                sortButton
            }
            
            settingsBlock
            
            unusedAssetsInfoBlock
            
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: Constants.groupMinWidth), spacing: 20, alignment: .top)
                    ],
                    alignment: .leading,
                    spacing: 20
                ) {
                    ForEach(Array(viewModel.similarityGroups.enumerated()), id: \.element) { index, group in
                        VStack(spacing: 12) {
                            groupNameAndSizeText(for: group, at: index)
                            
                            AssetImageView(asset: group.primary, size: Constants.imageSize)
                                .scaledToFit()
                                .background(.white)
                                .clipShape(.rect(cornerRadius: Constants.groupCornerRadius))
                            
                            VStack(spacing: .zero) {
                                similarAssetCountText(for: group)
                                
                                if !group.unusedAssets.isEmpty {
                                    unusedAssetsText(for: group)
                                }
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
                        .onTapGesture { viewModel.selectedGroup = group }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Groups")
        .padding()
        .onAppear { viewModel.setup() }
        .sheet(item: $viewModel.selectedGroup) { group in
            GroupDetailView(group: group) { selection in
                viewModel.delete(selection)
            }
        }
    }
    
    private var title: some View {
        Text("^[\(viewModel.similarityGroups.count) similarity group](inflect: true)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.title)
    }
    
    private var sortButton: some View {
        Menu {
            ForEach(GroupSortingCriterion.allCases, id: \.self) { criterion in
                Button {
                    viewModel.sortGroups(accordingTo: criterion)
                } label: {
                    HStack(spacing: .zero) {
                        if viewModel.currentSortingCriterion == criterion {
                            Image(systemName: "checkmark")
                        }
                        
                        Text(criterion.title)
                    }
                }
            }
        } label: {
            Text(viewModel.currentSortingCriterion.title.uppercased())
                .font(.subheadline)
                .bold()
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
    
    private var settingsBlock: some View {
        HStack {
            Text("THRESHOLD: \(viewModel.usedSettings.threshold.formatted(.number.precision(.fractionLength(1))))")
            
            Divider()
                .frame(maxHeight: Constants.settingsDividerHeight)
            
            Text("MINIMUM FILE SIZE: \(viewModel.usedSettings.minFileSize) KB")
            
            Divider()
                .frame(maxHeight: Constants.settingsDividerHeight)
            
            Text("USAGE CHECK: \(viewModel.usedSettings.shouldCheckUsage ? "ON": "OFF")")
            
            Spacer()
        }
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var unusedAssetsInfoBlock: some View {
        if viewModel.unusedGroupsCount > 0 {
            HStack(spacing: 4) {
                Text("Found ^[**\(viewModel.unusedGroupsCount)** unused groups](inflect: true) that can be safely deleted")
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Button {
                    viewModel.deleteAllUnusedGroups()
                } label: {
                    Label("DELETE ALL", systemImage: "trash.fill")
                }
                .buttonStyle(.customDestructive)
            }
            .frame(maxWidth: .infinity)
            .infoBox()
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
    }
    
    private func groupNameAndSizeText(for group: SimilarityGroup, at index: Int) -> some View {
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
    }
    
    private func similarAssetCountText(for group: SimilarityGroup) -> some View {
        Text("^[\(group.similar.count) similar asset](inflect: true)")
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .font(.caption)
    }
    
    private func strokeColor(for group: SimilarityGroup) -> Color {
        group.allUnused ? .orange.opacity(0.25) : .primary.opacity(0.25)
    }
    
    private func backgroundColor(for group: SimilarityGroup) -> Color {
        group.allUnused ? .orange.opacity(0.1) : Color.secondary.opacity(0.2)
    }
    
    private func unusedAssetsText(for group: SimilarityGroup) -> some View {
        let allUnused = group.allUnused
        let unusedCount = group.unusedAssets.count.description
        
        return HStack(alignment: .lastTextBaseline, spacing: allUnused ? 2 : 4) {
            Text(allUnused ? "ALL" : unusedCount)
                .bold()
                .font(allUnused ? .caption : .body)
                .foregroundStyle(.orange)
            
            Text("UNUSED")
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
    
    private func deleteAllButton(for group: SimilarityGroup) -> some View {
        Button {
            viewModel.delete(.group(group))
        } label: {
            Label("Delete", systemImage: "trash.fill")
        }
        .buttonStyle(.customDestructive)
    }
}

#Preview {
    let mockImageUrl = Bundle.main.url(forResource: "mock_icon", withExtension: "png")!
    
    GroupsView(
        .init(similarityGroups: (1...20).map { _ in
            SimilarityGroup(
                primary: ImageAsset(url: mockImageUrl, isUsed: Bool.random()), similar: (1...Int.random(in: 1...5)).map { _ in
                    (ImageAsset(url: mockImageUrl, isUsed: Bool.random()), Float.random(in: 0...1))
                }
            )
        }, usedSettings: .init(threshold: 0.5, minFileSize: 1, shouldCheckUsage: Bool.random()))
    )
    .frame(width: 600, height: 700)
}
