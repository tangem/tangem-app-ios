//
//  FeedWidgetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct FeedWidgetsView: View {
    @ObservedObject var viewModel: FeedWidgetsViewModel

    @ScaledMetric private var compactCardWidth: CGFloat = Constants.compactCardWidth
    @ScaledMetric private var compactCardHeight: CGFloat = Constants.compactCardHeight
    @ScaledMetric private var wideCardWidth: CGFloat = Constants.wideCardWidth
    @ScaledMetric private var accessorySide: CGFloat = Constants.accessorySide
    @ScaledMetric private var iconSide: CGFloat = Constants.iconSide
    @ScaledMetric private var productIconSide: CGFloat = Constants.productIconSide
    @ScaledMetric private var productGlyphSide: CGFloat = Constants.productGlyphSide
    @ScaledMetric private var payLogoWidth: CGFloat = Constants.payLogoWidth
    @ScaledMetric private var payLogoHeight: CGFloat = Constants.payLogoHeight

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: Constants.spacing) {
                    ForEach(viewModel.columns) { column in
                        view(for: column, productWidth: productCardWidth(in: geometry.size.width))
                    }
                }
                .padding(.horizontal, Constants.horizontalInset)
                .id(FeedConstants.widgetsAnchorID)
            }
        }
        .frame(height: columnHeight)
    }

    @ViewBuilder
    private func view(for column: FeedWidgetColumn, productWidth: CGFloat) -> some View {
        switch column {
        case .pair(let top, let bottom):
            VStack(spacing: Constants.spacing) {
                view(for: top, productWidth: productWidth)
                view(for: bottom, productWidth: productWidth)
            }
        case .single(let widget):
            view(for: widget, productWidth: productWidth)
        }
    }

    private func view(for widget: FeedWidget, productWidth: CGFloat) -> some View {
        Button {
            viewModel.select(widget)
        } label: {
            content(for: widget, productWidth: productWidth)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func content(for widget: FeedWidget, productWidth: CGFloat) -> some View {
        switch widget {
        case .forYou:
            smallWidget(title: Localization.forYouTitle) {
                FeedPortfolioDonutView()
            }

        case .addAccount:
            smallWidget(title: Localization.accountFormCreateButton) {
                addAccountIcon
            }

        case .startEarning(let state):
            productCard(
                caption: state.caption,
                message: state.message,
                appearance: .earn,
                width: productWidth
            )

        case .tangemPay:
            productCard(
                caption: Localization.feedPromoTangemPayTitle,
                message: Localization.feedPromoTangemPayDescription,
                appearance: .pay,
                width: productWidth
            )

        case .referFriend(let reward):
            productCard(
                caption: Localization.feedPromoReferralTitle,
                message: Localization.feedPromoReferralDescription(reward),
                appearance: .referral,
                width: productWidth
            )
        }
    }
}

// MARK: - Subviews

private extension FeedWidgetsView {
    var columnHeight: CGFloat {
        compactCardHeight * 2 + Constants.spacing
    }

    func productCardWidth(in availableWidth: CGFloat) -> CGFloat {
        guard viewModel.stretchesProductCard else { return wideCardWidth }

        let compactColumnCount = CGFloat(viewModel.columns.count - 1)
        let remainingWidth = availableWidth - Constants.horizontalInset * 2
            - compactColumnCount * (compactCardWidth + Constants.spacing)

        return max(wideCardWidth, remainingWidth)
    }

    var addAccountIcon: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconSide))
            .foregroundStyle(DesignSystem.Color.iconStaticDark)
            .frame(size: CGSize(bothDimensions: accessorySide))
            .background(DesignSystem.Color.bgAccentBlue, in: Circle())
            .overlay { Circle().strokeBorder(DesignSystem.Color.paletteOpaqueBaseWhite10, lineWidth: 0.5) }
            .accessibilityHidden(true)
    }

    func smallWidget(title: String, @ViewBuilder accessory: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            accessory()
                .frame(size: CGSize(bothDimensions: accessorySide))

            Spacer(minLength: 0)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, Constants.padding)
        .padding(.top, Constants.padding)
        .padding(.bottom, Constants.compactBottomPadding)
        .frame(width: compactCardWidth, height: compactCardHeight, alignment: .leading)
        .background(DesignSystem.Color.bgOpaquePrimary, in: RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    func iconSize(for appearance: ProductAppearance) -> CGSize {
        switch appearance {
        case .pay: CGSize(width: payLogoWidth, height: payLogoHeight)
        case .earn, .referral: CGSize(bothDimensions: productGlyphSide)
        }
    }

    var productAccessory: some View {
        DesignSystem.Icons.SignPlus.regular16.image
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(size: CGSize(bothDimensions: iconSide))
            .foregroundStyle(DesignSystem.Color.iconSecondary)
            .frame(size: CGSize(bothDimensions: accessorySide))
            .background(DesignSystem.Color.bgOpaquePrimary, in: Circle())
            .accessibilityHidden(true)
    }

    func productCard(
        caption: String,
        message: String,
        appearance: ProductAppearance,
        width: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            HStack(alignment: .top, spacing: 0) {
                appearance.icon
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(DesignSystem.Color.iconStaticDark)
                    .opacity(appearance.iconOpacity)
                    .frame(size: iconSize(for: appearance))
                    .frame(size: CGSize(bothDimensions: productIconSide))
                    .background {
                        FeedProductIconTileView(
                            color: appearance.iconColor,
                            showsHighlight: appearance != .pay,
                            side: productIconSide
                        )
                    }
                    .accessibilityHidden(true)

                Spacer(minLength: 0)

                productAccessory
                    .offset(x: Constants.productAccessoryOffset, y: -Constants.productAccessoryOffset)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                Text(message)
                    .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)
            }
        }
        .padding(Constants.padding)
        .frame(width: width, height: columnHeight, alignment: .leading)
        .background {
            DesignSystem.Color.bgOpaquePrimary
                .overlay { FeedProductGlowView(color: appearance.iconColor) }
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Auxiliary types

private extension FeedWidgetsView {
    enum ProductAppearance {
        case pay
        case earn
        case referral

        var icon: Image {
            switch self {
            case .pay: Assets.Visa.logo.image
            case .earn: DesignSystem.Icons.ChartLineVertical.regular20.image
            // [REDACTED_TODO_COMMENT]
            case .referral: Assets.Accounts.gift.image
            }
        }

        var iconOpacity: Double {
            self == .pay ? Constants.payIconOpacity : 1
        }

        var iconColor: Color {
            switch self {
            case .pay: Constants.payColor
            case .earn: DesignSystem.Color.bgAccentBlue
            case .referral: Constants.referralColor
            }
        }
    }
}

// MARK: - Constants

private extension FeedWidgetsView {
    enum Constants {
        static let spacing: CGFloat = 8
        static let horizontalInset: CGFloat = 16
        static let padding: CGFloat = 16
        static let compactBottomPadding: CGFloat = 12
        static let textSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 24
        static let accessorySide: CGFloat = 24
        static let iconSide: CGFloat = 16
        static let productIconSide: CGFloat = 40
        static let productGlyphSide: CGFloat = 20
        static let payLogoWidth: CGFloat = 22
        static let payLogoHeight: CGFloat = 8
        static let payIconOpacity = 0.9
        static let productAccessoryOffset: CGFloat = 4
        static let compactCardWidth: CGFloat = 120
        static let compactCardHeight: CGFloat = 86
        static let wideCardWidth: CGFloat = 186
        // [REDACTED_TODO_COMMENT]
        static let payColor = Color(red: 82 / 255, green: 50 / 255, blue: 243 / 255)
        static let referralColor = Color(red: 195 / 255, green: 83 / 255, blue: 121 / 255)
    }
}
