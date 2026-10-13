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
    let currencyCode: String?
    var hasOperationsInFlight = false
    let iconGeometryEffect: GeometryEffectPropertiesModel
    let iconBackgroundGeometryEffect: GeometryEffectPropertiesModel
    let nameGeometryEffect: GeometryEffectPropertiesModel
    let tokensCountGeometryEffect: GeometryEffectPropertiesModel
    let balanceGeometryEffect: GeometryEffectPropertiesModel

    /// Horizontal offset for positioning the invisible matchedGeometryEffect anchor point.
    @ScaledMetric private var geometryEffectAnchorOffset: CGFloat = 20

    @ScaledMetric private var pendingIndicatorSide: CGFloat = 20
    @ScaledMetric private var pendingIndicatorGlyphSize: CGFloat = 10
    @ScaledMetric private var pendingIndicatorBorderWidth: CGFloat = 2
    @ScaledMetric private var pendingIndicatorOffset: CGFloat = 4
    @ScaledMetric private var scaleFactor: CGFloat = 1

    private var balanceLoaderStyle: LoadableBalanceView.LoaderStyle {
        LoadableBalanceView.LoaderStyle(
            size: CGSize(width: 72, height: 16) * scaleFactor,
            cornerRadiusStyle: .capsule
        )
    }

    private var lineSpacing: CGFloat {
        4
    }

    private var contentPadding: CGFloat {
        12
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
                .overlay(alignment: .bottomTrailing) {
                    if hasOperationsInFlight {
                        pendingOperationIndicator
                            .offset(x: pendingIndicatorOffset, y: pendingIndicatorOffset)
                    }
                }
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
                    state: AttributedBalanceFormatter.decimalColored(
                        totalFiatBalance,
                        integerPart: AttributedBalanceFormatter.PartStyle(font: nil, color: TangemRowConstants.Style.Title.color),
                        fractionalPart: AttributedBalanceFormatter.PartStyle(font: nil, color: Color.Tangem.Text.Neutral.secondary)
                    ),
                    style: .init(
                        font: TangemRowConstants.Style.Title.font,
                        textColor: TangemRowConstants.Style.Title.color
                    ),
                    loader: balanceLoaderStyle
                )
            },
            secondaryLeadingView: {
                Text(tokensCount)
                    .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
                    .matchedGeometryEffect(tokensCountGeometryEffect)
            },
            secondaryTrailingView: {
                if let currencyCode {
                    Text(currencyCode)
                        .style(TangemRowConstants.Style.Subtitle.font, color: TangemRowConstants.Style.Subtitle.color)
                } else {
                    PriceChangeView(
                        state: priceChange,
                        showSkeletonWhenLoading: true,
                        showIconForNeutral: false,
                        isCapsuleSkeleton: true,
                        skeletonSize: CGSize(width: 40, height: 12) * scaleFactor
                    )
                }
            }
        )
        .linesSpacing(lineSpacing)
        .padding(contentPadding)
    }

    private var pendingOperationIndicator: some View {
        Circle()
            .fill(DesignSystem.Color.bgStatusWarningSubtle)
            .overlay {
                DesignSystem.Icons.Clock.regular12.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: pendingIndicatorGlyphSize, height: pendingIndicatorGlyphSize)
                    .foregroundStyle(DesignSystem.Color.iconStatusWarning)
            }
            .overlay {
                Circle().strokeBorder(DesignSystem.Color.bgSecondary, lineWidth: pendingIndicatorBorderWidth)
            }
            .frame(width: pendingIndicatorSide, height: pendingIndicatorSide)
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
            currencyCode: nil,
            iconGeometryEffect: effects.icon,
            iconBackgroundGeometryEffect: effects.iconBackground,
            nameGeometryEffect: effects.name,
            tokensCountGeometryEffect: effects.tokensCount,
            balanceGeometryEffect: effects.balance
        )
    }
}
