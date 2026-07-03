//
//  CollapsedAccountItemHeaderView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccounts

struct CollapsedAccountItemHeaderView: View {
    let name: String
    let iconData: AccountIconView.ViewData
    let tokensCount: String
    let totalFiatBalance: LoadableBalanceView.State
    let priceChange: PriceChangeView.State
    let iconGeometryEffect: GeometryEffectPropertiesModel
    let iconBackgroundGeometryEffect: GeometryEffectPropertiesModel
    let nameGeometryEffect: GeometryEffectPropertiesModel
    let tokensCountGeometryEffect: GeometryEffectPropertiesModel
    let balanceGeometryEffect: GeometryEffectPropertiesModel

    /// Horizontal offset for positioning the invisible matchedGeometryEffect anchor point.
    @ScaledMetric private var geometryEffectAnchorOffset: CGFloat = 20

    private var balanceLoaderStyle: LoadableBalanceView.LoaderStyle {
        FeatureProvider.isAvailable(.redesign)
            ? .init(size: .init(width: .unit(.x18), height: .unit(.x4)), cornerRadiusStyle: .capsule)
            : .init(size: .init(width: .unit(.x10), height: .unit(.x3)))
    }

    // [REDACTED_INFO]: drop gating, keep the redesign values (line spacing 4, padding 12).
    private var lineSpacing: CGFloat {
        FeatureProvider.isAvailable(.redesign) ? .unit(.x1) : 2
    }

    private var contentPadding: CGFloat {
        FeatureProvider.isAvailable(.redesign) ? .unit(.x3) : 14
    }

    var body: some View {
        TwoLineRowWithIcon(
            icon: {
                AccountIconView(
                    data: iconData.applyingLetterConfig(AccountItemConstants.letterConfig),
                    settings: AccountItemConstants.collapsedIconSettings,
                    iconGeometryEffect: iconGeometryEffect,
                    backgroundGeometryEffect: iconBackgroundGeometryEffect
                )
            },
            primaryLeadingView: {
                HStack(spacing: geometryEffectAnchorOffset) {
                    Text(name)
                        .style(TangemRowConstants.Style.Title.font, color: TangemRowConstants.Style.Title.color)
                        .matchedGeometryEffect(nameGeometryEffect)

                    Color.clear
                        .frame(size: .zero)
                        .matchedGeometryEffect(balanceGeometryEffect)
                }
            },
            primaryTrailingView: {
                LoadableBalanceView(
                    state: totalFiatBalance,
                    style: .init(font: Fonts.Regular.subheadline, textColor: Colors.Text.primary1),
                    loader: balanceLoaderStyle
                )
            },
            secondaryLeadingView: {
                Text(tokensCount)
                    .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
                    .matchedGeometryEffect(tokensCountGeometryEffect)
            },
            secondaryTrailingView: {
                PriceChangeView(
                    state: priceChange,
                    showSkeletonWhenLoading: true,
                    showIconForNeutral: false
                )
            }
        )
        .linesSpacing(lineSpacing)
        .padding(contentPadding)
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @Namespace var namespace

    ZStack {
        let effects = AccountGeometryEffects(namespace: namespace)

        Color.gray

        CollapsedAccountItemHeaderView(
            name: "Test",
            iconData: .composite(backgroundColor: .red, nameMode: .letter("A")),
            tokensCount: "5 Tokens",
            totalFiatBalance: .loaded(text: "$1234.56"),
            priceChange: .loaded(changeType: .positive, text: "+5.67%"),
            iconGeometryEffect: effects.icon,
            iconBackgroundGeometryEffect: effects.iconBackground,
            nameGeometryEffect: effects.name,
            tokensCountGeometryEffect: effects.tokensCount,
            balanceGeometryEffect: effects.balance
        )
    }
}
