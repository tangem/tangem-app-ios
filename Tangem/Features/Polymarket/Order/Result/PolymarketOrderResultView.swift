//
//  PolymarketOrderResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

struct PolymarketOrderResultView: View {
    @ObservedObject var viewModel: PolymarketOrderResultViewModel

    var body: some View {
        content
            .overlay(alignment: .topTrailing) {
                closeButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .interactiveDismissDisabled(viewModel.blocksSwipeDismiss)
    }

    private var closeButton: some View {
        TangemUI.Button(
            icon: DesignSystem.Icons.Cross.regular20,
            accessibilityLabel: Localization.commonClose,
            action: { viewModel.handleViewAction(.close) }
        )
        .size(.x11)
        .styleType(.material(.glass))
        .padding(Constants.closeButtonPadding)
    }

    @ViewBuilder
    private var content: some View {
        if let details = viewModel.details {
            screen.details { PolymarketOrderResultDetailsView(model: details) }
        } else {
            screen
        }
    }

    private var statusIcon: StatusIcon {
        let icon = StatusIcon(viewModel.glyph)

        guard let tint = viewModel.glyphTint else { return icon }

        return icon.tint(tint)
    }

    private var screen: StatusScreen<StatusIcon, EmptyView, EmptyView> {
        StatusScreen(
            title: viewModel.title,
            description: viewModel.description,
            actionTitle: viewModel.actionTitle,
            action: { viewModel.handleViewAction(viewModel.action) }
        )
        .appearance(viewModel.appearance)
        .actionLoading(viewModel.isAwaitingPosition)
        .actionDisabled(viewModel.isActionDisabled)
        .footerAxis(.horizontal)
        .footerHidden(viewModel.hidesFooter)
        .assetSlot { statusIcon }
    }
}

// MARK: - Constants

private extension PolymarketOrderResultView {
    enum Constants {
        static let closeButtonPadding: CGFloat = 16
    }
}

// MARK: - Previews

#Preview("Placed") {
    PolymarketOrderResultView(viewModel: .preview(state: .placed))
}

#Preview("Partially placed") {
    PolymarketOrderResultView(viewModel: .preview(state: .partiallyPlaced))
}

#Preview("No fill") {
    PolymarketOrderResultView(viewModel: .preview(state: .noFill))
}

#Preview("Still processing — Dark") {
    PolymarketOrderResultView(viewModel: .preview(state: .stillProcessing))
        .preferredColorScheme(.dark)
}

private extension PolymarketOrderResultViewModel {
    static func preview(state: State) -> PolymarketOrderResultViewModel {
        let market = PolymarketMarket.preview

        return PolymarketOrderResultViewModel(
            state: state,
            content: .init(
                market: .make(market: market, outcome: market.outcomes[1], eventTitle: "2026 FIFA World Cup winner"),
                placedAt: Date(),
                orderedAmount: 4000,
                filledAmount: 2000,
                tokensBought: 500,
                resolutionDate: Date().addingTimeInterval(60 * 60 * 24 * 365),
                side: .buy
            ),
            coordinator: nil
        )
    }
}
