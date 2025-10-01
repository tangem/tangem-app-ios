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

struct NewTokenSelectorGroupedSectionView: View {
    let viewModel: NewTokenSelectorGroupedSectionViewModel

    var body: some View {
        GroupedSection(viewModel.items) { item in
            NewTokenSelectorItemView(viewModel: item)
        } header: {
            switch viewModel.header {
            case .account(_, let name):
                DefaultHeaderView(name)
            case .wallet(let name):
                DefaultHeaderView(name)
            }
        }
    }
}
