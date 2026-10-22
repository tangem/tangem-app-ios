//
//  TransactionNotificationsItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct TransactionNotificationsItemView: View {
    @ObservedObject var viewModel: TransactionNotificationsItemViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                icon

                content

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Private UI

    private var icon: some View {
        NetworkIcon(
            imageAsset: viewModel.iconImageAsset,
            isActive: true,
            isDisabled: false,
            isMainIndicatorVisible: false,
            size: .init(bothDimensions: 24)
        )
        .shimmerPlaceholder(viewModel.isLoading, variant: .custom(cornerRadius: 14))
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            Shimmer()
                .variant(.custom(width: 70, height: 20, cornerRadius: 0))
        } else {
            text
        }
    }

    private var text: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(viewModel.networkName.uppercased())
                .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                .lineLimit(1)

            Text(viewModel.networkSymbol.uppercased())
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
    }
}
