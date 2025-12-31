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
    let sources: [NewsDetailsViewModel.Source]
    let onSourceTap: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(Localization.newsSources)
                    .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.primary)

                Text("\(sources.count)")
                    .style(Fonts.Bold.title3, color: Color.Tangem.Text.Neutral.tertiary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sources) { source in
                        NewsSourceCardView(source: source, onTap: onSourceTap)
                    }
                }
            }
        }
    }
}
