//
//  ExpandedAccountItemHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemAccounts
import TangemUIUtils

struct ExpandedAccountItemHeaderView: View {
    let name: String
    let iconData: AccountIconView.ViewData
    let totalFiatBalance: LoadableTokenBalanceView.State
    let iconGeometryEffect: GeometryEffectPropertiesModel
    let iconBackgroundGeometryEffect: GeometryEffectPropertiesModel
    let nameGeometryEffect: GeometryEffectPropertiesModel
    let tokensCountGeometryEffect: GeometryEffectPropertiesModel
    let balanceGeometryEffect: GeometryEffectPropertiesModel

    /// This mimics AccountIcon's scaledIconWidth so that we know its
    /// width to properly offset alignmentGuide for animation
    @ScaledMetric private var scaledIconWidth: CGFloat

    /// Heuristics for vertical offset for custom alignmentGuide
    @ScaledMetric private var verticalAlignmentGuideOffset: CGFloat = 10

    init(
        name: String,
        iconData: AccountIconView.ViewData,
        totalFiatBalance: LoadableTokenBalanceView.State,
        iconGeometryEffect: GeometryEffectPropertiesModel,
        iconBackgroundGeometryEffect: GeometryEffectPropertiesModel,
        nameGeometryEffect: GeometryEffectPropertiesModel,
        tokensCountGeometryEffect: GeometryEffectPropertiesModel,
        balanceGeometryEffect: GeometryEffectPropertiesModel
    ) {
        self.name = name
        self.iconData = iconData
        self.totalFiatBalance = totalFiatBalance
        self.iconGeometryEffect = iconGeometryEffect
        self.iconBackgroundGeometryEffect = iconBackgroundGeometryEffect
        self.nameGeometryEffect = nameGeometryEffect
        self.tokensCountGeometryEffect = tokensCountGeometryEffect
        self.balanceGeometryEffect = balanceGeometryEffect
        _scaledIconWidth = ScaledMetric(wrappedValue: AccountItemConstants.expandedIconSettings.size.width)
    }

    var body: some View {
        HStack(spacing: 6) {
            AccountInlineHeaderView(
                iconData: iconData.applyingLetterConfig(AccountItemConstants.letterConfig),
                name: name
            )
            .iconSettings(AccountItemConstants.expandedIconSettings)
            .font(Fonts.Bold.subheadline)
            .iconGeometryEffect(iconGeometryEffect)
            .iconBackgroundGeometryEffect(iconBackgroundGeometryEffect)
            .nameGeometryEffect(nameGeometryEffect)

            balanceView

            Spacer()

            Assets.Accounts.minimize.image
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.top, 14.0)
        // There is an additional padding of 6.0 pt somewhere in the view hierarchy,
        // there is why we use 2.0 pt here to make total 8.0 pt to match the mockup
        .padding(.bottom, 2.0)
        .overlay(alignment: .tokensCount) {
            // This is a "twin" of tokensCount label from CollapsedAccountItemHeaderView
            // for matchedGeometryEffect
            // We also have to define a custom alignmentGuide for tokensCount label
            // so it doesn't fly away but gently slides and disappears.
            alignmentPoint
                .alignmentGuide(HorizontalAlignment.tokensCount) { dimensions in
                    // Moving alignment point RIGHT
                    dimensions[.leading] -
                        Constants.horizontalPadding -
                        scaledIconWidth -
                        AccountItemConstants.expandedIconSettings.padding * 2 -
                        AccountInlineHeaderView.Constants.spacing
                }
                .alignmentGuide(VerticalAlignment.tokensCount) { dimensions in
                    dimensions[.bottom] - verticalAlignmentGuideOffset
                }
                .matchedGeometryEffect(tokensCountGeometryEffect)
        }
    }

    @ViewBuilder
    private var balanceView: some View {
        if totalFiatBalance.isLoaded {
            LoadableTokenBalanceView(
                state: totalFiatBalance,
                style: .init(font: Fonts.Bold.subheadline, textColor: Colors.Text.tertiary),
                loader: .init(size: .init(width: 40, height: 12))
            )
            .matchedGeometryEffect(balanceGeometryEffect)
        }
    }

    private var alignmentPoint: some View {
        Color.clear
            .frame(size: .zero)
    }
}

// MARK: - Constants

private extension ExpandedAccountItemHeaderView {
    enum Constants {
        static let horizontalPadding: CGFloat = 14
    }
}

// MARK: - Alignment

private extension VerticalAlignment {
    enum TokensCountAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.bottom]
        }
    }

    static let tokensCount = VerticalAlignment(TokensCountAlignment.self)
}

private extension HorizontalAlignment {
    enum TokensCountAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.leading]
        }
    }

    static let tokensCount = HorizontalAlignment(TokensCountAlignment.self)
}

private extension Alignment {
    static let tokensCount = Alignment(horizontal: .tokensCount, vertical: .tokensCount)
}
