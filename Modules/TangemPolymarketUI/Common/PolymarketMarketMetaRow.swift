//
//  PolymarketMarketMetaRow.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

public struct PolymarketMarketMetaRow: View {
    private let isLive: Bool
    private let category: Category?
    private let volume: Volume?

    public init(isLive: Bool = false, category: Category?, volume: Volume?) {
        self.isLive = isLive
        self.category = category
        self.volume = volume
    }

    public var body: some View {
        if isLive || category != nil || volume != nil {
            HStack(spacing: Constants.spacing) {
                if isLive {
                    liveBadge
                }

                if let category {
                    badge(category)
                }

                if let volume {
                    volumeView(volume)
                }
            }
        }
    }

    private var liveBadge: some View {
        // [REDACTED_TODO_COMMENT]
        Badge(label: "Live", accessibilityLabel: nil)
            .size(.x4)
            .variant(.solid)
            .appearance(.success)
            .slotStart(DesignSystem.Icons.Dot.filled12)
    }

    private func badge(_ category: Category) -> some View {
        HStack(spacing: 0) {
            if let icon = category.icon {
                icon.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSide, height: Constants.iconSide)
                    .foregroundStyle(DesignSystem.Color.iconSecondary)
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

            if volume.isHot {
                Assets.Polymarket.volumeFlame.image
                    .resizable()
                    .frame(width: Constants.iconSide, height: Constants.iconSide)
                    .accessibilityHidden(true)
            }
        }
        .font(token: DesignSystem.Font.captionMediumToken)
        .lineLimit(1)
    }
}

// MARK: - Models

public extension PolymarketMarketMetaRow {
    struct Category: Hashable {
        public let name: String
        public let icon: ImageType?

        public init(name: String, icon: ImageType?) {
            self.name = name
            self.icon = icon
        }
    }

    struct Volume: Hashable {
        public let title: String
        public let value: String
        public let isHot: Bool

        public init(title: String, value: String, isHot: Bool = false) {
            self.title = title
            self.value = value
            self.isHot = isHot
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
