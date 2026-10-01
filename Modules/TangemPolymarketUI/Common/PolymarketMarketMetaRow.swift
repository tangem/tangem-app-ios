//
//  PolymarketMarketMetaRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets

public struct PolymarketMarketMetaRow: View {
    private let category: Category?
    private let volume: Volume?

    public init(category: Category?, volume: Volume?) {
        self.category = category
        self.volume = volume
    }

    public var body: some View {
        if category != nil || volume != nil {
            HStack(spacing: Constants.spacing) {
                if let category {
                    badge(category)
                }

                if let volume {
                    volumeView(volume)
                }
            }
        }
    }

    private func badge(_ category: Category) -> some View {
        HStack(spacing: 0) {
            if let iconURL = category.iconURL {
                KFImage(iconURL)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSide, height: Constants.iconSide)
                    .accessibilityHidden(true)
            }

            Text(category.name)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, Constants.badgeInnerPadding)
        }
        .padding(.horizontal, Constants.badgeInnerPadding)
        .frame(minHeight: Constants.badgeMinHeight)
        .background(DesignSystem.Color.bgTransparentPrimary, in: Capsule())
    }

    private func volumeView(_ volume: Volume) -> some View {
        HStack(spacing: Constants.volumeSpacing) {
            Text(volume.title)
                .foregroundStyle(DesignSystem.Color.textSecondary)

            Text(volume.value)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
        .font(token: DesignSystem.Font.captionMediumToken)
        .lineLimit(1)
    }
}

// MARK: - Models

public extension PolymarketMarketMetaRow {
    struct Category: Hashable {
        public let name: String
        public let iconURL: URL?

        public init(name: String, iconURL: URL?) {
            self.name = name
            self.iconURL = iconURL
        }
    }

    struct Volume: Hashable {
        public let title: String
        public let value: String

        public init(title: String, value: String) {
            self.title = title
            self.value = value
        }
    }
}

// MARK: - Constants

private extension PolymarketMarketMetaRow {
    enum Constants {
        static let spacing: CGFloat = 8
        static let volumeSpacing: CGFloat = 4
        static let iconSide: CGFloat = 16
        static let badgeInnerPadding: CGFloat = 2
        static let badgeMinHeight: CGFloat = 16
    }
}
