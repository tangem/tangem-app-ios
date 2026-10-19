//
//  FeedSearchBarView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FeedSearchBarView: View {
    @ObservedObject var viewModel: FeedSearchBarViewModel
    let isActive: Bool
    let onFocus: () -> Void
    let onCancel: () -> Void
    let onHeightChange: (CGFloat) -> Void

    @Environment(\.mainShtorkaSize) private var sheetSize

    var body: some View {
        searchBar
            .infinityFrame(axis: .horizontal)
            .allowsHitTesting(!sheetSize.isNonFullFeedSheet)
            .accessibilityHidden(sheetSize.isNonFullFeedSheet)
            .overlay {
                if sheetSize.isNonFullFeedSheet {
                    SwiftUI.Button(action: focus) {
                        Color.clear
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localization.marketsSearchTitlePlaceholder)
                    .accessibilityIdentifier(MainAccessibilityIdentifiers.shtorkaExpandButton)
                }
            }
            .padding(.horizontal, Constants.horizontalInset)
            .padding(.top, Constants.topInset)
            .readGeometry(\.size.height, onChange: { reportSearchBar(height: $0) })
            .onChange(of: sheetSize) { size in
                if size.isNonFullFeedSheet {
                    viewModel.endEditing()
                }
            }
    }

    private var showsCancelButton: Bool {
        isActive || viewModel.isFocused
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Search(text: $viewModel.query, isActive: $viewModel.isFocused, onFocusChanged: focusDidChange)
                .placeholder(Localization.marketsSearchTitlePlaceholder)
                .showsCloseButton(false)
                .interactiveGlass(false)
                .prefersInset(sheetSize.isNonFullFeedSheet)
                .containerAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketFieldContainer)
                .textFieldAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketField)
                .clearButtonAccessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketClearButton)

            if showsCancelButton {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonCancel,
                    action: onCancel
                )
                .styleType(.material(.glass))
                .size(.x11)
                .accessibilityIdentifier(MainAccessibilityIdentifiers.searchThroughMarketCancelButton)
                .transition(.opacity)
            }
        }
        .animation(showsCancelButton ? Constants.openingAnimation : Constants.closingAnimation, value: showsCancelButton)
    }

    private func focus() {
        onFocus()
        viewModel.isFocused = true
    }

    private func focusDidChange(_ isFocused: Bool) {
        if isFocused {
            onFocus()
        }
    }

    private func reportSearchBar(height: CGFloat) {
        guard !viewModel.isFocused, viewModel.query.isEmpty else {
            return
        }

        onHeightChange(height)
    }
}

// MARK: - Constants

private extension FeedSearchBarView {
    enum Constants {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 16
        static let openingAnimation: Animation = .timingCurve(0.8, 0, 0.2, 1, duration: 0.3)
        static let closingAnimation: Animation = .timingCurve(0.8, 0, 0.8, 1, duration: 0.3)
    }
}
