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
import TangemUIUtils

struct NewsSourceCardView: View {
    let source: NewsSource
    let onTap: (NewsSource) -> Void

    var body: some View {
        redesignBody
    }

    // MARK: - Redesign

    private var redesignBody: some View {
        SwiftUI.Button {
            onTap(source)
        } label: {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: .zero) {
                    HStack(spacing: 4) {
                        Assets.Glyphs.exploreNew.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(size: .init(bothDimensions: 16))
                            .foregroundStyle(DesignSystem.Color.iconPrimary)

                        Text(source.sourceName)
                            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                            .lineLimit(1)
                    }

                    Text(source.title)
                        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
                        .lineLimit(RedesignConstants.titleLineLimit)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 8)

                    // Keep at least 32pt between the title and the date; with the fixed 132pt content
                    // height this pins the date to the bottom and adds more spacing for shorter titles.
                    Spacer(minLength: 32)

                    Text(source.publishedAt)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)

                if let imageUrl = source.imageUrl {
                    redesignThumbnail(url: imageUrl)
                }
            }
            .frame(height: RedesignConstants.contentHeight, alignment: .topLeading)
            .padding(16)
            .frame(width: RedesignConstants.cardWidth, alignment: .topLeading)
            .background(DesignSystem.Color.bgSecondary)
            .cornerRadiusContinuous(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .inset(by: 0.5)
                    .stroke(DesignSystem.Color.borderSecondary, lineWidth: 1)
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
