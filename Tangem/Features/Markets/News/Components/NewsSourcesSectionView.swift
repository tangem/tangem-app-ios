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
import TangemUIUtils

struct NewsSourcesSectionView: View {
    let sources: [NewsSource]
    let onSourceTap: (NewsSource) -> Void

    var body: some View {
        redesignContent
    }

    // MARK: - Redesign

    private var redesignContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.newsRelatedNews)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

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
