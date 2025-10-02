//
//  NewTokenSelectorGroupedSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

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
        case .account(_, let name):
            DefaultHeaderView(name)
        case .wallet(let name):
            DefaultHeaderView(name)
        }
    }
}
