//
//  PriceAlertsWatchlistItemView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

/// Built on the design-system `TangemRow` (Content Lead = Equal, Start + End slots, no divider):
/// the coin icon fills the start slot and a Delete button the end slot, while name/ticker and
/// price/change stack in the title/subtitle column.
struct PriceAlertsWatchlistItemView: View {
    let viewModel: PriceAlertsWatchlistItemViewModel
    let onDelete: () -> Void

    @ScaledMetric private var iconSize: CGFloat = 36

    var body: some View {
        TangemRow(title: viewModel.name, subtitle: viewModel.priceText)
            .titleAccessory { symbolView }
            .subtitleAccessory { priceChangeView }
            .start { iconView }
            .end { deleteButton }
            .contentLead(.equal)
            .showDivider(false)
    }

    private var iconView: some View {
        IconView(
            url: viewModel.iconURL,
            size: CGSize(width: iconSize, height: iconSize),
            forceKingfisher: true
        )
    }

    private var symbolView: some View {
        Text(viewModel.symbol)
            .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
            .lineLimit(1)
    }

    private var priceChangeView: some View {
        PriceChangeView(state: viewModel.priceChangeState, showSkeletonWhenLoading: false)
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Text(Localization.commonDelete)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Colors.Button.secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
