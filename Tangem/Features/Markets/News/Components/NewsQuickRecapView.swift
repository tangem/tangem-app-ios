//
//  NewsQuickRecapView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct NewsQuickRecapView: View {
    let content: String

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Separator(height: .exact(2), color: Color.Tangem.Border.Neutral.primary, axis: .vertical)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Assets.Glyphs.quickRecap.image
                        .foregroundStyle(Color.Tangem.Fill.Status.accent)

                    Text(Localization.newsQuickRecap)
                        .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Status.accent)
                }

                Text(content)
                    .style(Fonts.Regular.body, color: Color.Tangem.Text.Neutral.primary)
            }
            .padding(.leading, 16)
            .padding(.bottom, 8)
        }
    }
}
