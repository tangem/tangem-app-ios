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

    private let backgroundColor: Color

    init(
        viewModel: MainBottomSheetHeaderViewModel,
        backgroundColor: Color = .Tangem.Surface.level2
    ) {
        self.viewModel = viewModel
        self.backgroundColor = backgroundColor
    }

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
        .frame(height: Constants.searchFieldHeight)
        .padding(Constants.searchFieldPadding)
        .background(backgroundColor)
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

// MARK: - Constants

extension MainBottomSheetHeaderView {
    enum Constants {
        /// Not a scaled property because `RootViewControllerFactory` uses this control internally
        /// and its `Constants` values cannot be made scaled as it can't be added to the view hierarchy.
        static let searchFieldPadding: CGFloat = .unit(.x4)
        static let searchFieldHeight: CGFloat = .unit(.x11)
    }
}
