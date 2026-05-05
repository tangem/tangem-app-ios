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
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
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
                    .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
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
        .linesSpacing(2)
        .padding(14.0)
    }
}

#if DEBUG
private struct CollapsedAccountItemHeaderViewPreview: View {
    @Namespace private var namespace

    var body: some View {
        let effects = AccountGeometryEffects(namespace: namespace)

        ZStack {
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
}

#Preview {
    CollapsedAccountItemHeaderViewPreview()
}
#endif
