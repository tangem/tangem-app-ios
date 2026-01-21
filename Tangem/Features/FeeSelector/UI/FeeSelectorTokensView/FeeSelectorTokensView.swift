//
//  FeeSelectorTokensView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

struct FeeSelectorTokensView: View {
    @ObservedObject var viewModel: FeeSelectorTokensViewModel

    // MARK: - View Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RowSection(rows: viewModel.availableFeeCurrencyTokens)

                if viewModel.unavailableFeeCurrencyTokens.isNotEmpty {
                    RowSection(title: Localization.commonNotAvailable, rows: viewModel.unavailableFeeCurrencyTokens)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct RowSection: View {
    var title: String?
    var rows: [FeeSelectorRowViewModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                    .padding(.leading, 12)
            }

            VStack(spacing: 6) {
                ForEach(rows, id: \.self) {
                    FeeSelectorRowView(viewModel: $0)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
