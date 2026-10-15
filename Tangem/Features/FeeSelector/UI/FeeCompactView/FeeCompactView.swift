//
//  FeeCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct FeeCompactView: View {
    @ObservedObject var viewModel: FeeCompactViewModel
    let tapAction: (() -> Void)?

    private var isEmbedded = false

    init(viewModel: FeeCompactViewModel, tapAction: (() -> Void)?) {
        self.viewModel = viewModel
        self.tapAction = tapAction
    }

    var body: some View {
        if let tapAction, viewModel.canEditFee {
            SwiftUI.Button(action: tapAction) { content }
        } else {
            content
        }
    }

    private var content: some View {
        styled(row)
    }

    private var row: some View {
        BaseOneLineRow(
            icon: viewModel.showsLeadingIcon ? Assets.Glyphs.feeNew : nil,
            title: Localization.commonNetworkFeeTitle,
            secondLeadingView: {
                InfoButtonView(size: .medium, tooltipText: .attributed(text: viewModel.infoButtonString))
            },
            trailingView: {
                HStack(alignment: .center, spacing: 4) {
                    tokenItemBadge

                    LoadableTextView(
                        state: viewModel.selectedFeeComponents,
                        font: Fonts.Regular.body,
                        textColor: Colors.Text.tertiary,
                        loaderSize: CGSize(width: 40, height: 15)
                    )
                    .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeAmount)
                }
            }
        )
        .shouldShowTrailingIcon(viewModel.canEditFee)
    }

    private var style: Style {
        if isEmbedded {
            return .embedded
        }

        return viewModel.showsRoundedBackground ? .card : .plain
    }

    @ViewBuilder
    private func styled(_ row: some View) -> some View {
        switch style {
        case .card:
            row.defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 11, horizontalPadding: 14)
        case .embedded:
            row
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
        case .plain:
            row.padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var tokenItemBadge: some View {
        if let currencySymbol = viewModel.selectedFeeTokenCurrencySymbol {
            Text(currencySymbol)
                .style(Fonts.Bold.caption2, color: Colors.Text.secondary)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(Colors.Background.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityIdentifier(SendAccessibilityIdentifiers.networkFeeCurrencySymbol)
        }
    }
}

// MARK: - Style

private extension FeeCompactView {
    enum Style {
        case card
        case embedded
        case plain
    }
}

// MARK: - Setupable

extension FeeCompactView: Setupable {
    func embedded(_ isEmbedded: Bool) -> Self {
        map { $0.isEmbedded = isEmbedded }
    }
}
