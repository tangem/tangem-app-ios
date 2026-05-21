//
//  MainBottomSheetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI

struct MainBottomSheetHeaderView: View {
    @ObservedObject var viewModel: MainBottomSheetHeaderViewModel

    @FocusState private var isFocused: Bool

    @ScaledMetric private var fieldPadding: CGFloat = .unit(.x4)

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            bodyRedesign
        } else {
            bodyLegacy
        }
    }

    private var bodyRedesign: some View {
        TangemSearchField(
            text: $viewModel.enteredSearchText,
            focusAction: viewModel.focusSearchBarAction,
            clearAction: viewModel.clearSearchBarAction,
            cancelAction: viewModel.cancelSearchBarAction,
            onFocusChanged: viewModel.focusChangedAction
        )
        .placeholder(text: viewModel.searchPlaceholder)
        .cornerStyle(.capsule)
        .containerAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketFieldContainer)
        .textFieldAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketField)
        .clearButtonAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketClearButton)
        .padding(fieldPadding)
        .background(Color.Tangem.Surface.level2)
        .focused($isFocused)
        .onReceive(viewModel.$inputShouldBecomeFocused) { isFocused = $0 }
    }

    private var bodyLegacy: some View {
        MainBottomSheetHeaderInputView(
            searchText: $viewModel.enteredSearchText,
            isTextFieldFocused: $viewModel.inputShouldBecomeFocused,
            allowsHitTestingForTextField: true,
            clearButtonAction: viewModel.clearSearchBarAction,
            cancelButtonAction: viewModel.cancelSearchBarAction
        )
    }
}
