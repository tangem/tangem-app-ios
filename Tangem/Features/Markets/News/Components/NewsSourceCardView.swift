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
import TangemFoundation
import TangemUI

struct NewsSourceCardView: View {
    let source: NewsSource
    let onTap: (NewsSource) -> Void

    var body: some View {
        if FeatureProvider.isAvailable(.redesign) {
            redesignBody
        } else {
            legacyBody
        }
    }

    // MARK: - Redesign

    private var redesignBody: some View {
        Button {
            onTap(source)
        } label: {
            HStack(alignment: .top, spacing: .unit(.x4)) {
                VStack(alignment: .leading, spacing: .unit(.x2)) {
                    HStack(spacing: .unit(.x1)) {
                        Assets.Glyphs.exploreNew.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(size: .init(bothDimensions: 16))
                            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)

                        Text(source.sourceName)
                            .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                            .lineLimit(1)
                    }

                    Text(source.title)
                        .style(.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)
                        .lineLimit(RedesignConstants.titleLineLimit)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)

                    Text(source.publishedAt)
                        .style(.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                        .lineLimit(1)
                }

                if let imageUrl = source.imageUrl {
                    redesignThumbnail(url: imageUrl)
                }
            }
            .padding(.unit(.x4))
            .frame(width: RedesignConstants.cardWidth, alignment: .topLeading)
            .background(Color.Tangem.Surface.level3)
            .cornerRadiusContinuous(.unit(.x5))
            .overlay(
                RoundedRectangle(cornerRadius: .unit(.x5), style: .continuous)
                    .inset(by: 0.5)
                    .stroke(Color.Tangem.Border.Neutral.primary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func redesignThumbnail(url: URL) -> some View {
        KFImage(url)
            .cancelOnDisappear(true)
            .cacheMemoryOnly()
            .resizable()
            .scaledToFill()
            .frame(
                width: RedesignConstants.thumbnailSize,
                height: RedesignConstants.thumbnailSize
            )
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: RedesignConstants.thumbnailCornerRadius,
                    style: .continuous
                )
            )
    }

    private enum RedesignConstants {
        static let cardWidth: CGFloat = 228
        static let titleLineLimit: Int = 3
        static let thumbnailSize: CGFloat = 44
        static let thumbnailCornerRadius: CGFloat = 12
    }

    // MARK: - Legacy

    private var legacyBody: some View {
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
                        legacyThumbnail(url: imageUrl)
                    }
                }
                .padding(.bottom, 12)

                Spacer()

                Text(source.publishedAt)
                    .style(Fonts.Regular.footnote, color: Color.Tangem.Text.Neutral.tertiary)
            }
            .padding(LegacyConstants.padding)
            .frame(width: LegacyConstants.cardWidth, alignment: .leading)
            .frame(minHeight: LegacyConstants.minHeight, alignment: .top)
            .background(Color.Tangem.Surface.level3)
            .cornerRadius(LegacyConstants.cornerRadius)
        }
        .buttonStyle(.plain)
    }

    private func legacyThumbnail(url: URL) -> some View {
        KFImage(url)
            .cancelOnDisappear(true)
            .cacheMemoryOnly()
            .resizable()
            .scaledToFill()
            .frame(width: LegacyConstants.thumbnailSize, height: LegacyConstants.thumbnailSize)
            .clipped()
            .clipShape(
                RoundedRectangle(
                    cornerRadius: LegacyConstants.thumbnailCornerRadius,
                    style: .continuous
                )
            )
    }

    private enum LegacyConstants {
        static let cardWidth: CGFloat = 240
        static let minHeight: CGFloat = 140
        static let padding: CGFloat = 12
        static let cornerRadius: CGFloat = 12

        static let thumbnailSize: CGFloat = 48
        static let thumbnailCornerRadius: CGFloat = 4
    }
}
