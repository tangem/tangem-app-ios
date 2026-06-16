//
//  MarketsTokenNewsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemFoundation
import TangemAssets
import TangemUI

struct MarketsTokenNewsView: View {
    let items: [CarouselNewsItem]
    var onFourthItemAppear: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            header

            content
        }
        // Carousel bleeds past the 16pt horizontal padding that
        // `MarketsTokenDetailsContentViewRedesign` applies to the whole content stack — the same
        // edge-to-edge pattern the main Markets shtorka widget uses (`NewsWidgetViewRedesign`).
        .padding(.horizontal, -SizeUnit.x4.value)
    }

    // MARK: - Private Implementation

    private var header: some View {
        Text(Localization.newsRelatedNews)
            .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Mirrors the widget header's 16pt outer + 8pt inner horizontal padding.
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.horizontal, Constants.blockHeaderHorizontalPadding)
    }

    private var content: some View {
        CarouselNewsView(
            itemsState: .success(items),
            onItemAppear: { index in
                if index >= 3 {
                    onFourthItemAppear?()
                }
            }
        )
    }
}

private extension MarketsTokenNewsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 14
        static let blockHeaderHorizontalPadding: CGFloat = 8.0
    }
}
