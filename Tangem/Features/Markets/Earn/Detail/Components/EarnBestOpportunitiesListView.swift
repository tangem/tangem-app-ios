//
//  EarnBestOpportunitiesListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct EarnBestOpportunitiesListView: View {
    let viewModels: [EarnTokenItemViewModel]

    var body: some View {
        LazyVStack(spacing: Layout.itemSpacing) {
            ForEach(viewModels) { viewModel in
                EarnTokenItemView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension EarnBestOpportunitiesListView {
    enum Layout {
        static let itemSpacing: CGFloat = .zero
        static let horizontalPadding: CGFloat = 16.0
    }
}
