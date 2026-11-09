//
//  MobileBackupTypesView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct MobileBackupTypesView: View {
    typealias ViewModel = MobileBackupTypesViewModel

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        content
            .padding(.horizontal, 16)
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .navigationTitle(viewModel.navTitle)
            .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension MobileBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(indexed: viewModel.sections, id: \.0) { _, section in
                    sectionView(section)
                }
            }
            .padding(.top, 16)
        }
    }

    func sectionView(_ section: ViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            section.title.map {
                Text($0)
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textSecondary)
                    .padding(.leading, 14)
            }

            VStack(spacing: 8) {
                ForEach(indexed: section.items, id: \.0) { _, item in
                    sectionItemView(item)
                }
            }
        }
    }

    @ViewBuilder
    func sectionItemView(_ item: ViewModel.SectionItem) -> some View {
        switch item {
        case .seedPhrase(let viewModel):
            MobileBackupSeedPhraseTypeView(viewModel: viewModel)
        case .iCloud(let viewModel):
            MobileBackupICloudTypeView(viewModel: viewModel)
        case .upgrade(let viewModel):
            MobileBackupUpgradeTypeView(viewModel: viewModel)
        }
    }
}
