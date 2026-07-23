//
//  NewsSourcesSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI

struct NewsSourcesSectionView: View {
    let sources: [NewsSource]
    let onSourceTap: (NewsSource) -> Void

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            Text(Localization.newsRelatedNews)
                .style(Font.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .padding(.horizontal, .unit(.x4))
                .padding(.vertical, .unit(.x3))

            ScrollView(.horizontal) {
                HStack(spacing: .unit(.x3)) {
                    ForEach(sources) { source in
                        NewsSourceCardView(source: source, onTap: onSourceTap)
                    }
                }
                .padding(.horizontal, .unit(.x4))
            }
            .scrollIndicators(.hidden)
        }
    }
}
