//
//  NewsSourceCardView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Kingfisher
import SwiftUI
import TangemAssets
import TangemUI

struct NewsSourceCardView: View {
    let source: NewsDetailsViewModel.Source
    let onTap: (NewsDetailsViewModel.Source) -> Void

    private enum Constants {
        static let cardWidth: CGFloat = 240
        static let minHeight: CGFloat = 140
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 12

        static let thumbnailSize: CGFloat = 48
        static let thumbnailCornerRadius: CGFloat = 4
    }

    var body: some View {
        Button {
            onTap(source)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
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
                    }

                    if let imageUrl = source.imageUrl {
                        Spacer(minLength: 0)
                        thumbnail(url: imageUrl)
                    }
                }
                .padding(.bottom, 12)

                Spacer()

                Text(source.publishedAt)
                    .style(Fonts.Regular.footnote, color: Color.Tangem.Text.Neutral.tertiary)
            }
            .padding(Constants.padding)
            .frame(width: Constants.cardWidth, alignment: .leading)
            .frame(minHeight: Constants.minHeight, alignment: .top)
            .background(Color.Tangem.Surface.level4)
            .cornerRadius(Constants.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    private func thumbnail(url: URL) -> some View {
        KFImage(url)
            .cancelOnDisappear(true)
            .cacheMemoryOnly()
            .resizable()
            .scaledToFill()
            .frame(width: Constants.thumbnailSize, height: Constants.thumbnailSize)
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Constants.thumbnailCornerRadius,
                    style: .continuous
                )
            )
    }
}
