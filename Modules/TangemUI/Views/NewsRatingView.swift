//
//  NewsRatingView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct NewsRatingView: View {
    private let rating: String
    private let timeAgo: String

    public init(rating: String, timeAgo: String) {
        self.rating = rating
        self.timeAgo = timeAgo
    }

    public var body: some View {
        HStack(spacing: Layout.contentSpacing) {
            starIcon

            Text(rating)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)

            dotSeparator

            Text(timeAgo)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
        }
    }

    // MARK: - Components

    private var starIcon: some View {
        ZStack {
            Circle()
                .fill(Colors.Icon.attention)
                .frame(size: Layout.starCircleSize)

            Assets.star.image
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Colors.Icon.constant)
                .frame(size: Layout.starIconSize)
        }
    }

    private var dotSeparator: some View {
        Circle()
            .fill(Colors.Text.tertiary)
            .frame(size: Layout.dotSize)
    }

    private enum Layout {
        static let contentSpacing: CGFloat = 4
        static let starCircleSize: CGSize = .init(width: 12, height: 12)
        static let starIconSize: CGSize = .init(width: 8, height: 8)
        static let dotSize: CGSize = .init(width: 4, height: 4)
    }
}

// MARK: - Previews

#if DEBUG
struct NewsRatingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NewsRatingView(rating: "9.1", timeAgo: "1h ago")

            NewsRatingView(rating: "8.5", timeAgo: "2h ago")

            NewsRatingView(rating: "7.2", timeAgo: "3d ago")
        }
        .padding()
        .background(Colors.Background.primary)
        .previewLayout(.sizeThatFits)
    }
}
#endif
