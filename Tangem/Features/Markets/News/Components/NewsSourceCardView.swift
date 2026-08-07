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
        redesignBody
    }

    // MARK: - Redesign

    private var redesignBody: some View {
        Button {
            onTap(source)
        } label: {
            HStack(alignment: .top, spacing: .unit(.x4)) {
                VStack(alignment: .leading, spacing: .zero) {
                    HStack(spacing: .unit(.x1)) {
                        Assets.Glyphs.exploreNew.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(size: .init(bothDimensions: 16))
                            .foregroundStyle(Color.Tangem.Graphic.Neutral.primary)

                        Text(source.sourceName)
                            .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                            .lineLimit(1)
                    }

                    Text(source.title)
                        .style(Font.Tangem.Body16.regular, color: .Tangem.Text.Neutral.primary)
                        .lineLimit(RedesignConstants.titleLineLimit)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, .unit(.x2))

                    // Keep at least 32pt between the title and the date; with the fixed 132pt content
                    // height this pins the date to the bottom and adds more spacing for shorter titles.
                    Spacer(minLength: .unit(.x8))

                    Text(source.publishedAt)
                        .style(Font.Tangem.Caption12.semibold, color: .Tangem.Text.Neutral.secondary)
                        .lineLimit(1)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)

                if let imageUrl = source.imageUrl {
                    redesignThumbnail(url: imageUrl)
                }
            }
            .frame(height: RedesignConstants.contentHeight, alignment: .topLeading)
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
        static let cardWidth: CGFloat = 280
        static let contentHeight: CGFloat = 132
        static let titleLineLimit: Int = 3
        static let thumbnailSize: CGFloat = 44
        static let thumbnailCornerRadius: CGFloat = 12
    }
}
