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

    @State private var size: CGSize = .zero

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                icon

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(viewModel.networkName.uppercased())
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                        .lineLimit(1)
                        .skeletonable(isShown: viewModel.isLoading, width: 70, height: 20)

                    if !viewModel.isLoading {
                        Text(viewModel.networkSymbol.uppercased())
                            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .readGeometry(\.size, bindTo: $size)
    }

    // MARK: - Private UI

    private var icon: some View {
        NetworkIcon(
            imageAsset: viewModel.iconImageAsset,
            isActive: true,
            isDisabled: false,
            isMainIndicatorVisible: false,
            size: .init(bothDimensions: Constants.iconWidth)
        )
        .skeletonable(isShown: viewModel.isLoading, radius: 12)
    }
}

extension TransactionNotificationsItemView {
    enum Constants {
        static let iconWidth: Double = 24
    }
}
