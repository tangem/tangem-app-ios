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
            data: viewModel.marketListOrderTypeOptions,
            selection: $viewModel.marketListOrderType
        )
        .accessibilityIdentifier(MarketsAccessibilityIdentifiers.marketsSortButton)
    }

    private var timeIntervalPicker: some View {
        TangemSegmentedPicker(
            data: viewModel.marketPriceIntervalTypeOptions,
            selection: $viewModel.marketPriceIntervalType
        )
    }
}
