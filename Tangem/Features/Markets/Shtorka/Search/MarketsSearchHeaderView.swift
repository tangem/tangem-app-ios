//
//  MarketsSearchHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemUI

struct MarketsSearchHeaderView: View {
    @ObservedObject var viewModel: MarketsSearchHeaderViewModel

    var body: some View {
        Search(
            text: $viewModel.enteredSearchText,
            isActive: $viewModel.inputShouldBecomeFocused,
            clearAction: viewModel.clearSearchBarAction,
            cancelAction: viewModel.cancelSearchBarAction
        )
        .placeholder(viewModel.searchPlaceholder)
        .containerAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketFieldContainer)
        .textFieldAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketField)
        .clearButtonAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketClearButton)
        .closeButtonAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketCancelButton)
    }
}
