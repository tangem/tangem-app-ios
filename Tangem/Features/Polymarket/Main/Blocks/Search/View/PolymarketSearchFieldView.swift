//
//  PolymarketSearchFieldView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketSearchFieldView: View {
    @ObservedObject var viewModel: PolymarketSearchBlockViewModel

    var body: some View {
        HStack(spacing: Constants.cancelSpacing) {
            Search(
                text: $viewModel.query,
                isActive: $viewModel.isFieldActive,
                clearAction: { viewModel.handleViewAction(.clearQuery) }
            )
            .placeholder(Localization.commonSearch)
            .showsCloseButton(false)
            .interactiveGlass(false)
            .submitLabel(.search)

            if viewModel.isSearching {
                TangemUI.Button(
                    icon: DesignSystem.Icons.Cross.regular20,
                    accessibilityLabel: Localization.commonCancel,
                    action: { viewModel.handleViewAction(.cancel) }
                )
                .styleType(.material(.glass))
                .size(.x11)
                .transition(.opacity)
            }
        }
        .animation(viewModel.isSearching ? Constants.openingAnimation : Constants.closingAnimation, value: viewModel.isSearching)
        .padding(.horizontal, PolymarketMainLayout.horizontalPadding)
        .padding(.vertical, Constants.verticalPadding)
        .background(alignment: .bottom) {
            Fade(position: .bottom)
                .variant(.hard)
                .blurred()
                .padding(.top, -Constants.fadeOverhang)
                // With the keyboard up there is nothing below to fill, and stretching would drag the
                // scrim's opaque end under the keyboard, leaving the field on the transparent part.
                .ignoresSafeArea(edges: viewModel.isFieldActive ? [] : .bottom)
        }
    }
}

// MARK: - Constants

private extension PolymarketSearchFieldView {
    enum Constants {
        static let verticalPadding: CGFloat = 12
        static let fadeOverhang: CGFloat = 16
        static let cancelSpacing: CGFloat = 8
        static let openingAnimation: Animation = .timingCurve(0.8, 0, 0.2, 1, duration: 0.3)
        static let closingAnimation: Animation = .timingCurve(0.8, 0, 0.8, 1, duration: 0.3)
    }
}
