//
//  NewsSourceCardView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct NewsSourceCardView: View {
    let source: NewsDetailsViewModel.Source
    let onTap: (URL) -> Void

    var body: some View {
        Button {
            if let url = source.url {
                onTap(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Assets.Glyphs.exploreNew.image
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(Color.Tangem.Fill.Neutral.tertiaryConstant)

                    Text(source.sourceName)
                        .style(Fonts.Bold.footnote, color: Color.Tangem.Text.Neutral.tertiary)
                        .lineLimit(1)
                }
                .padding(.bottom, 4)

                Text(source.title)
                    .style(Fonts.Bold.subheadline, color: Color.Tangem.Text.Neutral.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 12)

                Spacer()

                Text(source.publishedAt)
                    .style(Fonts.Regular.footnote, color: Color.Tangem.Text.Neutral.tertiary)
            }
            .padding(12)
            .frame(width: 240, alignment: .leading)
            .frame(minHeight: 140, alignment: .top)
            .background(Color.Tangem.Surface.level4)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
