//
//  TokenRow.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TokenRow: View, Setupable {
    private let content: Content

    var accessibility: Accessibility = .combined(label: nil)

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isBalanceMasked) private var isBalanceMasked

    @ScaledMetric private var scale: CGFloat = 1
    @ScaledMetric private var padding: CGFloat = TokenRowMetrics.padding
    @ScaledMetric private var slotSpacing: CGFloat = TokenRowMetrics.slotSpacing
    @ScaledMetric private var lineSpacing: CGFloat = TokenRowMetrics.lineSpacing
    @ScaledMetric private var inlineSpacing: CGFloat = TokenRowMetrics.inlineSpacing
    @ScaledMetric private var balanceIndicatorSpacing: CGFloat = TokenRowMetrics.balanceIndicatorSpacing
    @ScaledMetric private var bubbleSpacing: CGFloat = TokenRowMetrics.bubbleSpacing
    @ScaledMetric private var quoteLineHeight: CGFloat = TokenRowMetrics.quoteLineHeight
    @ScaledMetric private var minTitleWidth: CGFloat = TokenRowMetrics.minTitleWidth
    @ScaledMetric private var bubbleTipInset: CGFloat = TangemMessageBubble.tipLeadingInset

    public init(_ content: Content) {
        self.content = content
    }

    public var body: some View {
        switch content {
        case .balance(
            let icon,
            let title,
            let titleAccessory,
            let quote,
            let priceChange,
            let balance,
            let indicator,
            let bubble,
            let onTap
        ):
            balanceRow(
                icon: icon,
                title: title,
                titleAccessory: titleAccessory,
                quote: quote,
                priceChange: priceChange,
                balance: balance,
                indicator: indicator,
                bubble: bubble,
                onTap: onTap
            )

        case .compact(let icon, let title, let ticker, let subtitle, let trailingIcon):
            compactRow(icon: icon, title: title, ticker: ticker, subtitle: subtitle, trailingIcon: trailingIcon)

        case .warning(let icon, let title, let quote, let priceChange, let text, let onTap):
            warningRow(icon: icon, title: title, quote: quote, priceChange: priceChange, text: text, onTap: onTap)

        case .note(let icon, let title, let quote, let priceChange, let text, let onTap):
            noteRow(icon: icon, title: title, quote: quote, priceChange: priceChange, text: text, onTap: onTap)

        case .shimmer:
            TokenRowSkeleton()
        }
    }
}

// MARK: - Balance

private extension TokenRow {
    func balanceRow(
        icon: Icon,
        title: String,
        titleAccessory: TokenRowTitleAccessory.Model?,
        quote: String?,
        priceChange: TokenRowPriceChange?,
        balance: Balance,
        indicator: BalanceIndicator?,
        bubble: TokenRowMessageBubble.Model?,
        onTap: @escaping () -> Void
    ) -> some View {
        pressableCell(
            onTap: onTap,
            hasExtraBottom: bubble != nil,
            main: {
                mainLine(
                    icon: icon.info,
                    isIconGrayscale: icon.isGrayscale,
                    contentLead: balance.hasSkeleton ? .equal : .end,
                    titleColumn: titleColumn(
                        title: title,
                        isTitleDimmed: balance.isStale,
                        quote: quote,
                        priceChange: priceChange,
                        titleAccessory: titleAccessory.map { titleAccessoryView($0) }
                    ),
                    valueColumn: balanceColumn(balance: balance, indicator: indicator)
                )
            },
            extraBottom: {
                if let bubble {
                    TokenRowMessageBubble(bubble)
                        .padding(.leading, padding + bubbleLeadingInset)
                        .padding(.trailing, padding)
                        .padding(.bottom, padding)
                }
            }
        )
    }

    func titleAccessoryView(_ model: TokenRowTitleAccessory.Model) -> some View {
        TokenRowTitleAccessory(model)
            .accessibilityIdentifier(identifiers?.titleAccessory)
            .layoutPriority(1)
    }

    func balanceColumn(balance: Balance, indicator: BalanceIndicator?) -> some View {
        VStack(alignment: .trailing, spacing: lineSpacing) {
            HStack(alignment: .center, spacing: balanceIndicatorSpacing) {
                if let indicator {
                    TokenRowGlyph.balanceIndicator(indicator)
                }

                if balance.isStale {
                    TokenRowGlyph.staleBalance
                }

                balanceLine(
                    balance.fiat.value,
                    token: DesignSystem.Font.bodyMediumToken,
                    color: DesignSystem.Color.textPrimary,
                    skeletonStyle: .body,
                    skeletonAlignment: .trailing,
                    accessibilityIdentifier: identifiers?.fiatBalance
                )
            }

            if let crypto = balance.crypto {
                balanceLine(
                    crypto,
                    token: DesignSystem.Font.captionMediumToken,
                    color: DesignSystem.Color.textSecondary,
                    skeletonStyle: .caption,
                    skeletonAlignment: .trailing,
                    accessibilityIdentifier: identifiers?.cryptoBalance
                )
            }
        }
    }

    @ViewBuilder
    func balanceLine(
        _ value: TokenRowValue,
        token: TangemTypographyToken,
        color: Color,
        skeletonStyle: Shimmer.TextStyle,
        skeletonAlignment: Shimmer.Alignment,
        accessibilityIdentifier: String?
    ) -> some View {
        switch value {
        case .loading:
            Shimmer()
                .variant(.text(style: skeletonStyle, alignment: skeletonAlignment))

        case .updating(let value):
            balanceText(
                value,
                isUpdating: true,
                token: token,
                color: color,
                accessibilityIdentifier: accessibilityIdentifier
            )

        case .loaded(let value):
            balanceText(
                value,
                isUpdating: false,
                token: token,
                color: color,
                accessibilityIdentifier: accessibilityIdentifier
            )
        }
    }

    func balanceText(
        _ value: UtilBalance.Value,
        isUpdating: Bool,
        token: TangemTypographyToken,
        color: Color,
        accessibilityIdentifier: String?
    ) -> some View {
        UtilBalance(value)
            .updating(isUpdating)
            .masked(isBalanceMasked)
            .style(token, color: color)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Compact

private extension TokenRow {
    func compactRow(
        icon: Icon,
        title: String,
        ticker: String,
        subtitle: CompactSubtitle,
        trailingIcon: ImageType?
    ) -> some View {
        padded(bottom: padding) {
            HStack(alignment: .center, spacing: slotSpacing) {
                tokenIcon(icon.info, isGrayscale: icon.isGrayscale)

                VStack(alignment: .leading, spacing: lineSpacing) {
                    HStack(alignment: .lastTextBaseline, spacing: inlineSpacing) {
                        titleText(title)

                        captionText(ticker)
                            .layoutPriority(1)
                    }

                    compactSubtitle(subtitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let trailingIcon {
                    TokenRowGlyph.trailing(trailingIcon)
                }
            }
        }
        .rowAccessibility(accessibilityShape)
    }

    @ViewBuilder
    func compactSubtitle(_ subtitle: CompactSubtitle) -> some View {
        switch subtitle {
        case .balance(let value):
            balanceLine(
                value,
                token: DesignSystem.Font.captionMediumToken,
                color: DesignSystem.Color.textSecondary,
                skeletonStyle: .caption,
                skeletonAlignment: .leading,
                accessibilityIdentifier: identifiers?.fiatBalance
            )

        case .message(let text):
            captionText(text)
        }
    }
}

// MARK: - Warning

private extension TokenRow {
    func warningRow(
        icon: TokenIconInfo,
        title: String,
        quote: String?,
        priceChange: TokenRowPriceChange?,
        text: String,
        onTap: @escaping () -> Void
    ) -> some View {
        pressableCell(onTap: onTap) {
            mainLine(
                icon: icon,
                isIconGrayscale: true,
                contentLead: .equal,
                titleColumn: titleColumn(title: title, quote: quote, priceChange: priceChange)
                    .opacity(TokenRowMetrics.dimmedOpacity),
                valueColumn: Badge(label: text, accessibilityLabel: nil)
                    .size(.x6)
                    .variant(.tinted)
                    .appearance(.warning)
            )
        }
    }
}

// MARK: - Note

private extension TokenRow {
    func noteRow(
        icon: TokenIconInfo,
        title: String,
        quote: String?,
        priceChange: TokenRowPriceChange?,
        text: String,
        onTap: @escaping () -> Void
    ) -> some View {
        pressableCell(onTap: onTap) {
            mainLine(
                icon: icon,
                isIconGrayscale: true,
                contentLead: .equal,
                titleColumn: titleColumn(title: title, quote: quote, priceChange: priceChange),
                valueColumn: Text(text)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.trailing)
            )
        }
    }
}

// MARK: - Shell

private extension TokenRow {
    func padded<Body: View>(bottom: CGFloat, @ViewBuilder content: () -> Body) -> some View {
        content()
            .opacity(isEnabled ? 1 : TokenRowMetrics.dimmedOpacity)
            .padding(EdgeInsets(top: padding, leading: padding, bottom: bottom, trailing: padding))
    }

    func pressableCell<Main: View, ExtraBottom: View>(
        onTap: @escaping () -> Void,
        hasExtraBottom: Bool,
        @ViewBuilder main: () -> Main,
        @ViewBuilder extraBottom: () -> ExtraBottom
    ) -> some View {
        PressableRow(
            onTap: onTap,
            accessorySpacing: bubbleSpacing,
            label: padded(bottom: hasExtraBottom ? 0 : padding, content: main)
                .rowAccessibility(accessibilityShape),
            accessory: extraBottom()
        )
    }

    func pressableCell<Main: View>(
        onTap: @escaping () -> Void,
        @ViewBuilder main: () -> Main
    ) -> some View {
        pressableCell(onTap: onTap, hasExtraBottom: false, main: main, extraBottom: { EmptyView() })
    }

    func mainLine(
        icon: TokenIconInfo,
        isIconGrayscale: Bool = false,
        contentLead: RowContentLead,
        titleColumn: some View,
        valueColumn: some View
    ) -> some View {
        HStack(alignment: .center, spacing: slotSpacing) {
            tokenIcon(icon, isGrayscale: isIconGrayscale)

            RowContentLayout(contentLead: contentLead, minOppositeWidth: minTitleWidth) {
                titleColumn
                valueColumn
            }
            .frame(maxWidth: .infinity)
        }
    }

    func titleColumn(
        title: String,
        quote: String?,
        priceChange: TokenRowPriceChange?
    ) -> some View {
        titleColumn(title: title, quote: quote, priceChange: priceChange, titleAccessory: EmptyView())
    }

    func titleColumn(
        title: String,
        isTitleDimmed: Bool = false,
        quote: String?,
        priceChange: TokenRowPriceChange?,
        titleAccessory: some View
    ) -> some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            HStack(alignment: .center, spacing: inlineSpacing) {
                titleText(title, isDimmed: isTitleDimmed)

                titleAccessory
            }

            quoteLine(quote: quote, priceChange: priceChange)
        }
    }

    func quoteLine(quote: String?, priceChange: TokenRowPriceChange?) -> some View {
        HStack(alignment: .center, spacing: inlineSpacing) {
            if let quote {
                captionText(quote)
            }

            if let priceChange {
                UtilPriceChange(value: priceChange.value, direction: priceChange.direction)
                    .updating(priceChange.isUpdating)
                    .layoutPriority(1)
            }
        }
        .frame(minHeight: quoteLineHeight)
    }
}

// MARK: - Leaves

private extension TokenRow {
    func titleText(_ text: String, isDimmed: Bool = false) -> some View {
        TokenRowTitleText(text, isDimmed: isDimmed, accessibilityIdentifier: identifiers?.name)
    }

    func captionText(_ text: String) -> some View {
        TokenRowCaptionText(text)
    }

    func tokenIcon(_ icon: TokenIconInfo, isGrayscale: Bool = false) -> some View {
        TokenRowTokenIcon(icon, isGrayscale: isGrayscale)
    }
}

// MARK: - Geometry

private extension TokenRow {
    var bubbleLeadingInset: CGFloat {
        TokenRowMetrics.iconSize.containerWidth(atScale: scale) + slotSpacing - bubbleTipInset
    }
}

// MARK: - Accessibility

private extension TokenRow {
    var accessibilityShape: RowAccessibility.Shape {
        switch accessibility {
        case .combined(let label): .element(label: label)
        case .leaves: .container
        }
    }

    var identifiers: AccessibilityIdentifiers? {
        switch accessibility {
        case .combined: nil
        case .leaves(let identifiers): identifiers
        }
    }
}
