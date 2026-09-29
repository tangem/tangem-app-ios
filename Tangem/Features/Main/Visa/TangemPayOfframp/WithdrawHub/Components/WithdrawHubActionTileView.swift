//
//  WithdrawHubActionTileView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

struct WithdrawHubActionTileView: View {
    let data: ViewData

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        if let action = data.action {
            SwiftUI.Button(action: action) {
                tile.opacity(isEnabled ? 1 : 0.6)
            }
            .buttonStyle(.defaultScaled)
        } else {
            tile
        }
    }
}

// MARK: - Subviews

private extension WithdrawHubActionTileView {
    var tile: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top, spacing: Constants.badgeSpacing) {
                icon

                Spacer(minLength: .zero)

                badge
            }

            Spacer(minLength: Constants.minContentSpacing)

            VStack(alignment: .leading, spacing: Constants.titleSpacing) {
                Text(data.title)
                    .style(DesignSystem.Font.subheadingMediumToken, color: data.titleForeground)
                    .multilineTextAlignment(.leading)

                subtitle
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Constants.tilePadding)
        .background(
            data.backgroundColor,
            in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
        )
        .overlay(border)
    }

    @ViewBuilder
    var icon: some View {
        switch data {
        case .action(let icon, _, _):
            glyph(icon, tint: DesignSystem.Color.iconStaticDark, background: DesignSystem.Color.bgStatusInfo)

        case .placeholder(let icon, _):
            glyph(icon, tint: DesignSystem.Color.iconSecondary, background: DesignSystem.Color.bgTertiary)

        case .seeAll:
            glyph(
                DesignSystem.Icons.DotsHorizontal.regular20,
                tint: DesignSystem.Color.iconPrimary,
                background: DesignSystem.Color.bgTertiary
            )

        case .recentAccount(let account):
            Text(account.monogram)
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
                .frame(width: Constants.iconBackgroundSide, height: Constants.iconBackgroundSide)
                .background(DesignSystem.Color.bgTertiary, in: Circle())

        case .recentToken(let token):
            TokenIconV2(tokenIconInfo: token.tokenIconInfo, size: .size40)

        case .retry:
            glyph(
                DesignSystem.Icons.ArrowRefresh.regular20,
                tint: DesignSystem.Color.iconInverse,
                background: DesignSystem.Color.bgInverse
            )
        }
    }

    func glyph(_ icon: ImageType, tint: Color, background: Color) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.iconSide, height: Constants.iconSide)
            .foregroundStyle(tint)
            .frame(width: Constants.iconBackgroundSide, height: Constants.iconBackgroundSide)
            .background(background, in: Circle())
    }

    @ViewBuilder
    var badge: some View {
        if case .recentToken = data {
            Badge(label: Localization.tangempayWithdrawHubRecentBadge, accessibilityLabel: nil)
                .size(.x4)
                .appearance(.neutral)
        }
    }

    @ViewBuilder
    var subtitle: some View {
        switch data {
        case .action, .placeholder, .seeAll, .retry:
            EmptyView()

        case .recentAccount(let account):
            Text(account.accountNumber)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

        case .recentToken(let token):
            HStack(spacing: Constants.accountIconSpacing) {
                Text(token.accountName)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                AccountIconView(data: token.accountIcon, settings: .smallSized)
            }
        }
    }

    @ViewBuilder
    var border: some View {
        switch data {
        case .placeholder, .retry:
            RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [3]))
                .foregroundColor(DesignSystem.Color.borderSecondary)
        default:
            EmptyView()
        }
    }
}

// MARK: - ViewData

extension WithdrawHubActionTileView {
    enum ViewData {
        case action(icon: ImageType, title: String, action: () -> Void)
        case placeholder(icon: ImageType, title: String)
        case seeAll(action: () -> Void)
        case recentAccount(RecentAccount)
        case recentToken(RecentToken)
        case retry(title: String, action: () -> Void)
    }

    struct RecentAccount {
        let monogram: String
        let name: String
        let accountNumber: String
        let action: () -> Void
    }

    struct RecentToken {
        let tokenIconInfo: TokenIconInfo
        let name: String
        let accountIcon: AccountIconView.ViewData
        let accountName: String
        let action: () -> Void
    }
}

private extension WithdrawHubActionTileView.ViewData {
    var title: String {
        switch self {
        case .action(_, let title, _),
             .placeholder(_, let title),
             .retry(let title, _):
            title
        case .seeAll:
            Localization.commonSeeAll
        case .recentAccount(let account):
            account.name
        case .recentToken(let token):
            token.name
        }
    }

    var backgroundColor: Color {
        switch self {
        case .action:
            DesignSystem.Color.bgStatusInfoSubtle
        case .seeAll, .recentAccount, .recentToken:
            DesignSystem.Color.bgSecondary
        case .placeholder, .retry:
            Color.clear
        }
    }

    var titleForeground: Color {
        switch self {
        case .placeholder, .retry:
            DesignSystem.Color.textSecondary
        default:
            DesignSystem.Color.textPrimary
        }
    }

    var action: (() -> Void)? {
        switch self {
        case .action(_, _, let action),
             .seeAll(let action),
             .retry(_, let action):
            action
        case .placeholder: nil
        case .recentAccount(let account): account.action
        case .recentToken(let token): token.action
        }
    }
}

// MARK: - Constants

extension WithdrawHubActionTileView {
    enum Constants {
        static let tilePadding: CGFloat = 16
        static let cornerRadius: CGFloat = 20

        static let iconSide: CGFloat = 20
        static let iconBackgroundSide: CGFloat = 32

        static let minContentSpacing: CGFloat = 8
        static let titleSpacing: CGFloat = 2
        static let badgeSpacing: CGFloat = 4
        static let accountIconSpacing: CGFloat = 4
    }
}

// MARK: - Previews

#Preview("Action") {
    WithdrawHubActionTileView(
        data: .action(
            icon: DesignSystem.Icons.ArrowSwapHorizontal.regular20,
            title: "Within your portfolio",
            action: {}
        )
    )
    .frame(width: 160, height: 136)
}

#Preview("Placeholder") {
    WithdrawHubActionTileView(
        data: .placeholder(
            icon: DesignSystem.Icons.Heart.regular20,
            title: "Your recent transfers will be here"
        )
    )
    .frame(width: 160, height: 136)
}

#Preview("See all") {
    WithdrawHubActionTileView(data: .seeAll(action: {}))
        .frame(width: 160, height: 136)
}

#Preview("Retry") {
    WithdrawHubActionTileView(
        data: .retry(title: "Unable to load the data", action: {})
    )
    .frame(width: 160, height: 136)
}

#Preview("Recent account") {
    WithdrawHubActionTileView(
        data: .recentAccount(
            .init(monogram: "P", name: "Pablo E", accountNumber: "0000000000", action: {})
        )
    )
    .frame(width: 160, height: 136)
}

#Preview("Recent token") {
    WithdrawHubActionTileView(
        data: .recentToken(
            .init(
                tokenIconInfo: .remote(name: "Polygon", imageURL: nil),
                name: "Polygon",
                accountIcon: .composite(backgroundColor: .blue, nameMode: .imageType(Assets.Accounts.starAccounts)),
                accountName: "Main account",
                action: {}
            )
        )
    )
    .frame(width: 160, height: 136)
}
