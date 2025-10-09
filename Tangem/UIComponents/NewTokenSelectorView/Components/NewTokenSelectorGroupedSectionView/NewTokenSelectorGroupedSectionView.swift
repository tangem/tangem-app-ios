//
//  NewTokenSelectorGroupedSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct NewTokenSelectorGroupedSectionView: View {
    let viewModel: NewTokenSelectorGroupedSectionViewModel

    var body: some View {
        GroupedSection(viewModel.items) { item in
            NewTokenSelectorItemView(viewModel: item)
        } header: {
            NewTokenSelectorGroupedSectionHeaderView(header: viewModel.header)
        }
    }
}

struct NewTokenSelectorGroupedSectionHeaderView: View {
    let header: NewTokenSelectorGroupedSectionViewModel.HeaderType

    var body: some View {
        content
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    var content: some View {
        switch header {
        case .account(let icon, let name):
            HStack(spacing: 6) {
                AccountIconView(data: icon)
                    .settings(.smallSized)

                Text(name)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }
        case .wallet(let name):
            Text(name)
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
        }
    }
}
