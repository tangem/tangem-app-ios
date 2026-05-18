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
        if FeatureProvider.isAvailable(.redesign) {
            redesignContent
        } else {
            legacyContent
        }
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: .unit(.x3)) {
            Text(Localization.newsRelatedNews)
                .style(.Tangem.Heading20.semibold, color: .Tangem.Text.Neutral.primary)
                .padding(.horizontal, .unit(.x4))

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

    // MARK: - Legacy

    private var legacyContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(Localization.newsSources)
                    .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)

                Text("\(sources.count)")
                    .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.tertiary)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(sources) { source in
                        NewsSourceCardView(source: source, onTap: onSourceTap)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }
}
