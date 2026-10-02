//
//  PolymarketOrderResultDetailsView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

public struct PolymarketOrderResultDetailsView: View {
    private let model: Model

    public init(model: Model) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: Constants.spacing) {
            if let banner = model.banner {
                bannerView(banner)
            }

            PolymarketOrderMarketRow(model: model.market)
                .backgroundColor(DesignSystem.Color.bgTransparentPrimary)

            if let tokensBoughtText = model.tokensBoughtText {
                rows(tokensBoughtText: tokensBoughtText)
            }
        }
    }

    private func bannerView(_ banner: Banner) -> some View {
        MessageBanner(
            title: AttributedString(banner.title),
            description: AttributedString(banner.description)
        )
        .variant(banner.style.variant)
        .glowRing(banner.style.glowRing)
        .slotEnd { infoIcon }
    }

    private var infoIcon: some View {
        DesignSystem.Icons.Info.regular20.image
            .renderingMode(.template)
            .resizable()
            .frame(width: Constants.infoIconSide, height: Constants.infoIconSide)
            .foregroundStyle(DesignSystem.Color.iconPrimary)
    }

    private func rows(tokensBoughtText: String) -> some View {
        VStack(spacing: 0) {
            TangemUI.Row(title: model.tokensTitle, value: tokensBoughtText)
                .overrideTextColors(Constants.valueColors)
                .showDivider(model.resolutionDateText != nil)

            if let resolutionDateText = model.resolutionDateText {
                TangemUI.Row(title: Localization.predictionDetailsResolutionDate, value: resolutionDateText)
                    .overrideTextColors(Constants.valueColors)
                    .showDivider(false)
            }
        }
    }
}

// MARK: - Model

public extension PolymarketOrderResultDetailsView {
    struct Model {
        public let banner: Banner?
        public let market: PolymarketOrderMarketRow.Model
        public let tokensBoughtText: String?
        public let resolutionDateText: String?
        public let tokensTitle: String

        public init(
            banner: Banner?,
            market: PolymarketOrderMarketRow.Model,
            tokensBoughtText: String?,
            resolutionDateText: String?,
            tokensTitle: String = Localization.predictionPlaceResultTokensBought
        ) {
            self.banner = banner
            self.market = market
            self.tokensBoughtText = tokensBoughtText
            self.resolutionDateText = resolutionDateText
            self.tokensTitle = tokensTitle
        }
    }

    struct Banner {
        public let title: String
        public let description: String
        public let style: Style

        public init(title: String, description: String, style: Style) {
            self.title = title
            self.description = description
            self.style = style
        }
    }

    enum Style {
        case partialFill
        case noFill
    }
}

// MARK: - Appearance

private extension PolymarketOrderResultDetailsView.Style {
    var variant: MessageBannerVariant {
        switch self {
        case .partialFill: .warning
        case .noFill: .error
        }
    }

    var glowRing: GlowRingAppearance {
        switch self {
        case .partialFill: .warning
        case .noFill: .error
        }
    }
}

// MARK: - Constants

private extension PolymarketOrderResultDetailsView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let infoIconSide: CGFloat = 20
        static let valueColors = RowOverrideTextColors(value: DesignSystem.Color.textSecondary)
    }
}
