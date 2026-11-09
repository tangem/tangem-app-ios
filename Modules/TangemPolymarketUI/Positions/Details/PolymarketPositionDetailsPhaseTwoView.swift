//
//  PolymarketPositionDetailsPhaseTwoView.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

public struct PolymarketPositionDetailsPhaseTwoView: View {
    private let model: Model
    private let onBack: () -> Void

    @State private var headerHeight: CGFloat = 0

    public init(model: Model, onBack: @escaping () -> Void) {
        self.model = model
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .top) {
            content

            header
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: .zero) { footer }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        PolymarketTopBar(onBack: onBack)
            .padding(.bottom, Constants.headerBottomPadding)
            .readGeometry(\.size.height, bindTo: $headerHeight)
            .background {
                Fade(position: .top)
                    .blurred()
                    .backgroundColor(DesignSystem.Color.bgPrimary)
                    .ignoresSafeArea(edges: .top)
            }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                summary
                    .padding(.horizontal, Constants.summaryHorizontalPadding)
                    .padding(.bottom, Constants.blockSpacing - Constants.summaryBottomPaddingOverDesign)

                VStack(spacing: Constants.blockSpacing) {
                    if let notice = model.notice {
                        PolymarketPositionNoticeView(notice: notice, variant: .default)
                            .padding(.bottom, Constants.noticeBottomPadding)
                    }

                    VStack(spacing: Constants.groupSpacing) {
                        market

                        values

                        PolymarketPositionPriceRangeView(model: model.priceRange)

                        if let realizedProfit = model.realizedProfit {
                            realizedProfitTile(realizedProfit)
                        }
                    }

                    PolymarketDetailsRowsBlock(rows: model.rows, rowVerticalPadding: Constants.rowVerticalPadding)
                }
                .padding(.horizontal, Constants.horizontalPadding)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: headerHeight)
        }
    }

    private var summary: some View {
        ModalStatus(title: model.summary.question) {
            PolymarketAvatarView(url: model.summary.iconURL, side: Constants.summaryIconSide)
        }
        .extraBottom {
            HStack(spacing: Constants.voteSpacing) {
                Text(Localization.predictionPlaceYouVote)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                Badge(label: model.summary.outcomeTitle, accessibilityLabel: nil)
                    .size(.x6)
                    .appearance(model.summary.outcomeStyle.badgeAppearance)
            }
            .padding(.horizontal, Constants.voteHorizontalPadding)
            .accessibilityElement(children: .combine)
        }
    }

    private var market: some View {
        TangemUI.Row(title: model.market.title)
            .titleLineLimit(Constants.marketTitleLineLimit)
            .verticalAlignment(.center)
            .end { PolymarketAvatarView(url: model.market.iconURL) }
            .onTap(action: model.market.onTap)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
    }

    private var values: some View {
        HStack(alignment: .top, spacing: Constants.groupSpacing) {
            tile(caption: model.currentValue.caption, value: model.currentValue.valueText) {
                UtilPriceChange(value: model.currentValue.changeText, direction: model.currentValue.changeDirection)
                    .typography(DesignSystem.Font.subheadingMediumToken)
                    .accessibilityLabel(model.currentValue.changeAccessibilityLabel)
            }

            if let payout = model.payout {
                tile(caption: payout.caption, value: payout.valueText, hasGlow: true) {
                    Badge(label: payout.profitText, accessibilityLabel: nil)
                        .size(.x4)
                        .appearance(.warning)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var payoutGlow: some View {
        Ellipse()
            .fill(DesignSystem.Color.bgStatusWarning)
            .frame(size: Constants.glowSize)
            .blur(radius: Constants.glowBlurRadius)
            .opacity(Constants.glowOpacity)
            .padding(.leading, Constants.glowLeadingInset)
            .padding(.bottom, Constants.glowBottomInset)
            .accessibilityHidden(true)
    }

    private func realizedProfitTile(_ realizedProfit: RealizedProfit) -> some View {
        SwiftUI.Button(action: realizedProfit.onHintTap) {
            tile(caption: realizedProfit.caption, value: realizedProfit.valueText, hasHint: true) {
                EmptyView()
            }
        }
        .buttonStyle(.plain)
    }

    private func tile<Accessory: View>(
        caption: String,
        value: String,
        hasHint: Bool = false,
        hasGlow: Bool = false,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.tileSpacing) {
            HStack(spacing: Constants.captionSpacing) {
                Text(caption)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                    .lineLimit(1)

                if hasHint {
                    PolymarketHintIcon(asset: DesignSystem.Icons.Info.regular16)
                }
            }

            Text(value)
                .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(Constants.minimumScaleFactor)

            accessory()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Constants.tilePadding)
        .background(alignment: .bottomLeading) {
            ZStack(alignment: .bottomLeading) {
                DesignSystem.Color.bgSecondary

                if hasGlow {
                    payoutGlow
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        HStack(spacing: Constants.groupSpacing) {
            actionButton(model.secondaryAction, styleType: .secondary(.default))

            actionButton(model.primaryAction, styleType: .primary)
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background {
            Fade(position: .bottom)
                .variant(.hard)
                .backgroundColor(DesignSystem.Color.bgPrimary)
                .padding(.top, -Constants.footerFadeOverhang)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func actionButton(_ action: PolymarketPositionDetailsView.Action, styleType: TangemUI.Button.StyleType) -> some View {
        TangemUI.Button(label: action.title, accessibilityLabel: action.title, action: action.perform)
            .styleType(styleType)
            .size(.x12)
            .horizontalLayout(.infinity)
            .loading(.spinner(if: action.isLoading))
            .disabled(!action.isEnabled)
    }
}

// MARK: - Model

public extension PolymarketPositionDetailsPhaseTwoView {
    struct Model {
        public let summary: Summary
        public let notice: PolymarketPositionNotice?
        public let market: Market
        public let currentValue: CurrentValue
        public let payout: Payout?
        public let priceRange: PolymarketPositionPriceRangeView.Model
        public let realizedProfit: RealizedProfit?
        public let rows: [PolymarketDetailsRowsBlock.Row]
        public let secondaryAction: PolymarketPositionDetailsView.Action
        public let primaryAction: PolymarketPositionDetailsView.Action

        public init(
            summary: Summary,
            notice: PolymarketPositionNotice?,
            market: Market,
            currentValue: CurrentValue,
            payout: Payout?,
            priceRange: PolymarketPositionPriceRangeView.Model,
            realizedProfit: RealizedProfit?,
            rows: [PolymarketDetailsRowsBlock.Row],
            secondaryAction: PolymarketPositionDetailsView.Action,
            primaryAction: PolymarketPositionDetailsView.Action
        ) {
            self.summary = summary
            self.notice = notice
            self.market = market
            self.currentValue = currentValue
            self.payout = payout
            self.priceRange = priceRange
            self.realizedProfit = realizedProfit
            self.rows = rows
            self.secondaryAction = secondaryAction
            self.primaryAction = primaryAction
        }
    }

    struct Summary {
        public let iconURL: URL?
        public let question: String
        public let outcomeTitle: String
        public let outcomeStyle: PolymarketOutcomeStyle

        public init(iconURL: URL?, question: String, outcomeTitle: String, outcomeStyle: PolymarketOutcomeStyle) {
            self.iconURL = iconURL
            self.question = question
            self.outcomeTitle = outcomeTitle
            self.outcomeStyle = outcomeStyle
        }
    }

    struct Market {
        public let title: String
        public let iconURL: URL?
        public let onTap: () -> Void

        public init(title: String, iconURL: URL?, onTap: @escaping () -> Void) {
            self.title = title
            self.iconURL = iconURL
            self.onTap = onTap
        }
    }

    struct CurrentValue {
        public let caption: String
        public let valueText: String
        public let changeText: String
        public let changeDirection: UtilPriceChange.Direction

        public init(caption: String, valueText: String, changeText: String, changeDirection: UtilPriceChange.Direction) {
            self.caption = caption
            self.valueText = valueText
            self.changeText = changeText
            self.changeDirection = changeDirection
        }
    }

    struct Payout {
        public let caption: String
        public let valueText: String
        public let profitText: String

        public init(caption: String, valueText: String, profitText: String) {
            self.caption = caption
            self.valueText = valueText
            self.profitText = profitText
        }
    }

    struct RealizedProfit {
        public let caption: String
        public let valueText: String
        public let onHintTap: () -> Void

        public init(caption: String, valueText: String, onHintTap: @escaping () -> Void) {
            self.caption = caption
            self.valueText = valueText
            self.onHintTap = onHintTap
        }
    }
}

// MARK: - Accessibility

private extension PolymarketPositionDetailsPhaseTwoView.CurrentValue {
    var changeAccessibilityLabel: String {
        switch changeDirection {
        case .positive:
            "\(String.plusSign) \(changeText)"
        case .negative:
            "\(String.minusSign) \(changeText)"
        case .neutral:
            changeText
        }
    }
}

// MARK: - Outcome badge

private extension PolymarketOutcomeStyle {
    var badgeAppearance: BadgeAppearance {
        switch self {
        case .affirmative:
            .info
        case .negative:
            .error
        case .neutral:
            .neutral
        }
    }
}

// MARK: - Constants

private extension PolymarketPositionDetailsPhaseTwoView {
    enum Constants {
        static let headerBottomPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let summaryHorizontalPadding: CGFloat = 8
        static let summaryBottomPaddingOverDesign: CGFloat = 16
        static let summaryIconSide: CGFloat = 72
        static let voteSpacing: CGFloat = 4
        static let voteHorizontalPadding: CGFloat = 8
        static let blockSpacing: CGFloat = 12
        static let noticeBottomPadding: CGFloat = 12
        static let rowVerticalPadding: CGFloat = 12
        static let groupSpacing: CGFloat = 8
        static let tileSpacing: CGFloat = 2
        static let captionSpacing: CGFloat = 4
        static let tilePadding: CGFloat = 16
        static let cornerRadius: CGFloat = 24
        static let marketTitleLineLimit = 1
        static let minimumScaleFactor: CGFloat = 0.7
        static let footerVerticalPadding: CGFloat = 8
        static let footerFadeOverhang: CGFloat = 16
        static let glowSize = CGSize(width: 240, height: 126)
        static let glowBlurRadius: CGFloat = 40
        static let glowOpacity: CGFloat = 0.08
        static let glowLeadingInset: CGFloat = -88
        static let glowBottomInset: CGFloat = -70
    }
}
