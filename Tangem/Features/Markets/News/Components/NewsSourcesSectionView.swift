//
//  NewsSourcesSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct NewsSourcesSectionView: View {
    let sources: [NewsSource]
    let onSourceTap: (NewsSource) -> Void

    var body: some View {
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
