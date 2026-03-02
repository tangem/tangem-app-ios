//
//  AccountsAwareNetworkSelectorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AccountsAwareNetworkSelectorView: View {
    let viewModel: AccountsAwareNetworkSelectorViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 0)) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.itemViewModels) { itemViewModel in
                    AccountsAwareNetworkSelectorItemView(viewModel: itemViewModel)
                }
            }
        }
        .roundedBackground(with: Colors.Background.action, padding: 0)
        .scrollBounceBehavior(.basedOnSize)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }
}
