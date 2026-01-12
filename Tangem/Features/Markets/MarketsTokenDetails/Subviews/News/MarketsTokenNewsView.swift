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

struct MarketsTokenNewsView: View {
    let items: [CarouselNewsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            header

            content
        }
    }

    // MARK: - Private Implementation

    private var header: some View {
        Text(Localization.newsRelatedNews)
            .style(Fonts.Bold.title3, color: Colors.Text.primary1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.horizontal, Constants.blockHeaderHorizontalPadding)
    }

    private var content: some View {
        CarouselNewsView(itemsState: .success(items))
    }
}

private extension MarketsTokenNewsView {
    enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 14
        static let blockHeaderHorizontalPadding: CGFloat = 8.0
    }
}
