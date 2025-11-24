//
//  NewTokenSelectorAccountView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemAccounts

struct NewTokenSelectorAccountView: View {
    @ObservedObject var viewModel: NewTokenSelectorAccountViewModel

    var body: some View {
        if let items = viewModel.items {
            GroupedSection(items) { item in
                NewTokenSelectorItemView(viewModel: item)
            } header: {
                NewTokenSelectorAccountHeaderView(header: viewModel.header)
            }
            .backgroundColor(Colors.Background.action)
        }
    }
}
