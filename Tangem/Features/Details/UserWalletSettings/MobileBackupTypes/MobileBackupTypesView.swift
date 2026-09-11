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
            .background(Colors.Background.secondary.ignoresSafeArea())
            .navigationTitle(viewModel.navTitle)
            .onFirstAppear(perform: viewModel.onFirstAppear)
    }
}

// MARK: - Subviews

private extension MobileBackupTypesView {
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(Array(viewModel.sections.enumerated()), id: \.offset) { _, section in
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
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 14)
            }

            VStack(spacing: 8) {
                ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
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
