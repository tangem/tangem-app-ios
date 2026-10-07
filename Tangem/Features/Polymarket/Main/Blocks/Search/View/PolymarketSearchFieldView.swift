//
//  PolymarketSearchFieldView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketSearchFieldView: View {
    @ObservedObject var viewModel: PolymarketSearchBlockViewModel

    var body: some View {
        Search(
            text: $viewModel.query,
            isActive: $viewModel.isFieldActive,
            clearAction: { viewModel.handleViewAction(.clearQuery) },
            cancelAction: { viewModel.handleViewAction(.cancel) }
        )
        .placeholder(Localization.commonSearch)
        .submitLabel(.search)
        .padding(.horizontal, Constants.horizontalPadding)
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
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let fadeOverhang: CGFloat = 16
    }
}
