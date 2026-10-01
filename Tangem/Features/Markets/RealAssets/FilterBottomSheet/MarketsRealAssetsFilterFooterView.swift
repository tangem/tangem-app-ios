//
//  MarketsRealAssetsFilterFooterView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers

struct MarketsRealAssetsFilterFooterView: View {
    @ObservedObject var viewModel: MarketsRealAssetsFilterBottomSheetViewModel

    var body: some View {
        FilterFooterView(
            isVisible: viewModel.showsFooter,
            onReset: viewModel.reset,
            onApply: viewModel.apply,
            resetAccessibilityIdentifier: MarketsAccessibilityIdentifiers.marketsRealAssetsFilterResetButton,
            applyAccessibilityIdentifier: MarketsAccessibilityIdentifiers.marketsRealAssetsFilterApplyButton
        )
    }
}
