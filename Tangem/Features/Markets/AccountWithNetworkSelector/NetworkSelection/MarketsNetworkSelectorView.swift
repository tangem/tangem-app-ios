//
//  MarketsNetworkSelectorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsNetworkSelectorView: View {
    let viewModel: MarketsNetworkSelectorViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .leading, spacing: 0)) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.tokenItemViewModels) { viewModel in
                    MarketsNetworkItemView(viewModel: viewModel)
                }
            }
        }
        .roundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 16)
        .scrollBounceBehavior(.basedOnSize)
        .padding(.bottom, 16)
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }
}
