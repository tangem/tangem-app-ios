//
//  MarketsRatingHeaderViewRedesign.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAccessibilityIdentifiers

struct MarketsRatingHeaderViewRedesign: View {
    @ObservedObject var viewModel: MarketsRatingHeaderViewModel

    var body: some View {
        HStack {
            orderButtonView

            Spacer()

            timeIntervalPicker
        }
    }

    private var orderButtonView: some View {
        TangemDropDown(
            singleSelection: $viewModel.marketListOrderType,
            in: viewModel.marketListOrderTypeOptions
        )
        .accessibilityIdentifier { order in
            MarketsAccessibilityIdentifiers.marketsSortOption(order.rawValue)
        }
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSortButton)
    }

    private var timeIntervalPicker: some View {
        TangemSegmentedPicker(
            data: viewModel.marketPriceIntervalTypeOptions,
            selection: $viewModel.marketPriceIntervalType
        )
        .accessibilityIdentifier { interval in
            MarketsAccessibilityIdentifiers.marketsIntervalSegment(interval.marketsAccessibilityId)
        }
    }
}
