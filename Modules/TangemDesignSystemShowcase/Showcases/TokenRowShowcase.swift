//
//  TokenRowShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TokenRowShowcase: View {
    @State private var configuration = Configuration()
    @State private var isRowEnabled = true
    @State private var isMasked = false
    @State private var tapCount = 0
    @State private var bubbleTapCount = 0
    @State private var closeCount = 0

    var body: some View {
        DSShowcase("TokenRow") { controls in
            controls.picker("Case", $configuration.contentCase)

            if configuration.contentCase == .balance {
                controls.picker("Title accessory", $configuration.titleAccessory)

                if configuration.titleAccessory == .reward {
                    controls.toggle("Reward is active", $configuration.rewardIsActive)
                    controls.toggle("Reward is updating", $configuration.rewardIsUpdating)
                }

                controls.toggle("Crypto balance", $configuration.showCrypto)

                if configuration.showCrypto {
                    controls.picker("Crypto balance state", $configuration.cryptoState, options: BalanceStateOption.allCases, label: \.label)
                }

                controls.toggle("Message bubble", $configuration.showBubble)

                if configuration.showBubble {
                    controls.toggle("Bubble icon", $configuration.bubbleHasIcon)
                    controls.toggle("Bubble chevron", $configuration.bubbleHasChevron)
                }

                if configuration.titleAccessory == .reward || configuration.showBubble {
                    controls.picker("Accent", $configuration.accent)
                }

                if configuration.fiatState == .loaded {
                    controls.toggle("Stale balance", $configuration.isStale)
                }

                controls.picker("Balance indicator", $configuration.indicator)
            }

            if configuration.contentCase == .compact {
                controls.picker("Subtitle", $configuration.compactSubtitle)
                controls.toggle("Trailing icon", $configuration.showTrailingIcon)
            }

            if configuration.contentCase == .balance || configuration.contentCase == .compact {
                controls.toggle("Grayscale icon", $configuration.isIconGrayscale)
            }

            if configuration.contentCase == .balance || (configuration.contentCase == .compact && configuration.compactSubtitle == .balance) {
                controls.toggle("Attributed balances", $configuration.isAttributed)
                controls.picker("Fiat balance", $configuration.fiatState, options: BalanceStateOption.allCases, label: \.label)
            }

            if configuration.contentCase != .compact, configuration.contentCase != .shimmer {
                controls.toggle("Quote", $configuration.showQuote)
                controls.picker("Price change", $configuration.priceChange)

                if configuration.priceChange != PriceChangeOption.none {
                    controls.toggle("Updating price change", $configuration.isPriceChangeUpdating)
                }
            }

            if configuration.contentCase != .shimmer {
                controls.toggle("Enabled", $isRowEnabled)
                controls.toggle("Overflowing text", $configuration.overflow)
            }

            controls.toggle("Masked balances", $isMasked)
            controls.readout("Taps", "\(tapCount)")
            controls.readout("Bubble taps", "\(bubbleTapCount)")
            controls.readout("Dismissals", "\(closeCount)")
        } stage: {
            row(configuration, isInteractive: true)
                .disabled(!isRowEnabled)
                .environment(\.isBalanceMasked, isMasked)
        } matrix: {
            DSShowcaseGroup("Content") {
                DSShowcaseMatrix(rows: ContentCase.allCases) { contentCase in
                    matrixRow(Configuration(contentCase: contentCase))
                }
            }

            DSShowcaseGroup("Balance state") {
                DSShowcaseMatrix(rows: BalanceStateOption.allCases, columns: BalanceStateOption.allCases, rowLabel: { "fiat \($0.label)" }, columnLabel: { "crypto \($0.label)" }) { fiatState, cryptoState in
                    matrixRow(Configuration(fiatState: fiatState, cryptoState: cryptoState))
                }
            }

            DSShowcaseGroup("Reward") {
                DSShowcaseMatrix(rows: TokenRowAccent.allCases, columns: RewardStateOption.allCases) { accent, rewardState in
                    matrixRow(
                        Configuration(
                            accent: accent,
                            rewardIsActive: rewardState != .inactive,
                            rewardIsUpdating: rewardState == .updating
                        )
                    )
                }
            }

            DSShowcaseGroup("Title accessory") {
                DSShowcaseMatrix(rows: TitleAccessoryOption.allCases) { titleAccessory in
                    matrixRow(Configuration(titleAccessory: titleAccessory))
                }
            }

            DSShowcaseGroup("Price change") {
                DSShowcaseMatrix(rows: PriceChangeOption.allCases, columns: [false, true], columnLabel: { $0 ? "updating" : "idle" }) { priceChange, isUpdating in
                    matrixRow(Configuration(priceChange: priceChange, isPriceChangeUpdating: isUpdating))
                }
            }

            DSShowcaseGroup("Balance indicator") {
                DSShowcaseMatrix(rows: IndicatorOption.allCases, columns: [false, true], columnLabel: { $0 ? "stale" : "fresh" }) { indicator, isStale in
                    matrixRow(Configuration(isStale: isStale, indicator: indicator))
                }
            }

            DSShowcaseGroup("Message bubble") {
                DSShowcaseMatrix(rows: TokenRowAccent.allCases, columns: [false, true], columnLabel: { $0 ? "chevron" : "close" }) { accent, hasChevron in
                    matrixRow(Configuration(accent: accent, showBubble: true, bubbleHasChevron: hasChevron))
                }
            }

            DSShowcaseGroup("Compact") {
                DSShowcaseMatrix(rows: CompactSubtitleOption.allCases, columns: [true, false], columnLabel: { $0 ? "trailing icon" : "no icon" }) { subtitle, hasTrailingIcon in
                    matrixRow(Configuration(contentCase: .compact, compactSubtitle: subtitle, showTrailingIcon: hasTrailingIcon))
                }
            }

            DSShowcaseGroup("Overflowing text") {
                DSShowcaseMatrix(rows: ContentCase.allCases.filter { $0 != .shimmer }) { contentCase in
                    matrixRow(Configuration(contentCase: contentCase, showBubble: contentCase == .balance, overflow: true))
                }
            }

            DSShowcaseGroup("Disabled") {
                DSShowcaseMatrix(rows: ContentCase.allCases.filter { $0 != .shimmer }) { contentCase in
                    matrixRow(Configuration(contentCase: contentCase))
                        .disabled(true)
                }
            }

            DSShowcaseGroup("Masked balances") {
                DSShowcaseMatrix(rows: [ContentCase.balance, .compact]) { contentCase in
                    matrixRow(Configuration(contentCase: contentCase))
                        .environment(\.isBalanceMasked, true)
                }
            }
        }
    }

    private func matrixRow(_ configuration: Configuration) -> some View {
        row(configuration, isInteractive: false)
            .frame(width: 343)
    }

    private func row(_ configuration: Configuration, isInteractive: Bool) -> some View {
        TokenRow(content(configuration, isInteractive: isInteractive))
    }

    private func content(_ configuration: Configuration, isInteractive: Bool) -> TokenRow.Content {
        let onTap: () -> Void = isInteractive ? { tapCount += 1 } : {}

        switch configuration.contentCase {
        case .balance:
            return TokenRow.Content.balance(
                icon: TokenRow.Icon(Self.iconInfo, isGrayscale: configuration.isIconGrayscale),
                title: configuration.title,
                titleAccessory: titleAccessoryModel(configuration),
                quote: configuration.showQuote ? configuration.quote : nil,
                priceChange: configuration.priceChange.value(isUpdating: configuration.isPriceChangeUpdating),
                balance: TokenRow.Balance(
                    fiat: fiatBalanceValue(configuration),
                    crypto: configuration.showCrypto ? balanceValue(configuration.cryptoState, configuration.crypto, isAttributed: configuration.isAttributed) : nil
                ),
                indicator: configuration.indicator.value,
                bubble: configuration.showBubble ? bubbleModel(configuration, isInteractive: isInteractive) : nil,
                onTap: onTap
            )

        case .compact:
            return TokenRow.Content.compact(
                icon: TokenRow.Icon(Self.iconInfo, isGrayscale: configuration.isIconGrayscale),
                title: configuration.title,
                ticker: configuration.ticker,
                subtitle: compactSubtitleValue(configuration),
                trailingIcon: configuration.showTrailingIcon ? DesignSystem.Icons.SignEqual.regular24 : nil
            )

        case .warning:
            return TokenRow.Content.warning(
                icon: Self.iconInfo,
                title: configuration.title,
                quote: configuration.showQuote ? configuration.quote : nil,
                priceChange: configuration.priceChange.value(isUpdating: configuration.isPriceChangeUpdating),
                text: configuration.warningText,
                onTap: onTap
            )

        case .note:
            return TokenRow.Content.note(
                icon: Self.iconInfo,
                title: configuration.title,
                quote: configuration.showQuote ? configuration.quote : nil,
                priceChange: configuration.priceChange.value(isUpdating: configuration.isPriceChangeUpdating),
                text: configuration.noteText,
                onTap: onTap
            )

        case .shimmer:
            return TokenRow.Content.shimmer
        }
    }

    private func titleAccessoryModel(_ configuration: Configuration) -> TokenRowTitleAccessory.Model? {
        switch configuration.titleAccessory {
        case .none:
            return nil

        case .reward:
            return TokenRowTitleAccessory.Model.reward(
                TokenRowTitleAccessory.Model.Reward(
                    label: configuration.rewardLabel,
                    accent: configuration.accent,
                    isActive: configuration.rewardIsActive,
                    isUpdating: configuration.rewardIsUpdating
                )
            )

        case .pending:
            return TokenRowTitleAccessory.Model.pending(accessibilityLabel: "Transaction in progress")
        }
    }

    private func bubbleModel(_ configuration: Configuration, isInteractive: Bool) -> TokenRowMessageBubble.Model {
        TokenRowMessageBubble.Model(
            text: configuration.overflow
                ? "Enable 5.47% APY on your balance and start earning rewards every single day"
                : "Enable 5.47% APY on your balance",
            variant: configuration.accent == .yield ? .success : .info,
            icon: configuration.bubbleHasIcon ? Self.bubbleIcon(for: configuration.accent) : nil,
            trailingAccessory: configuration.bubbleHasChevron ? .chevron : .close(action: {
                guard isInteractive else { return }
                closeCount += 1
                withAnimation { self.configuration.showBubble = false }
            }),
            onTap: {
                guard isInteractive else { return }
                bubbleTapCount += 1
            }
        )
    }

    private func compactSubtitleValue(_ configuration: Configuration) -> TokenRow.CompactSubtitle {
        switch configuration.compactSubtitle {
        case .balance:
            return TokenRow.CompactSubtitle.balance(balanceValue(configuration.fiatState, configuration.fiat, isAttributed: configuration.isAttributed))
        case .message:
            return TokenRow.CompactSubtitle.message(configuration.warningText)
        }
    }

    private func fiatBalanceValue(_ configuration: Configuration) -> TokenRow.Balance.Fiat {
        let text = balanceText(configuration.fiat, isAttributed: configuration.isAttributed)

        switch configuration.fiatState {
        case .loading:
            return TokenRow.Balance.Fiat.loading
        case .updating:
            return TokenRow.Balance.Fiat.updating(text)
        case .loaded:
            return TokenRow.Balance.Fiat.loaded(text, isStale: configuration.isStale)
        }
    }

    private func balanceValue(_ state: BalanceStateOption, _ string: String, isAttributed: Bool) -> TokenRowValue {
        switch state {
        case .loading:
            return TokenRowValue.loading
        case .updating:
            return TokenRowValue.updating(balanceText(string, isAttributed: isAttributed))
        case .loaded:
            return TokenRowValue.loaded(balanceText(string, isAttributed: isAttributed))
        }
    }

    private func balanceText(_ string: String, isAttributed: Bool) -> UtilBalance.Value {
        guard isAttributed else {
            return UtilBalance.Value.string(string)
        }

        var attributed = AttributedString(string)

        if let separator = attributed.range(of: Locale.current.decimalSeparator ?? ".") {
            attributed[separator.lowerBound ..< attributed.endIndex].foregroundColor = DesignSystem.Color.textSecondary
        }

        return UtilBalance.Value.attributed(attributed)
    }

    static var iconInfo: TokenIconInfo {
        TokenIconInfo(
            name: "Bitcoin",
            blockchainIconAsset: Tokens.bitcoinFill,
            imageURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/bitcoin.png"),
            isCustom: false,
            customTokenColor: nil
        )
    }

    private static func bubbleIcon(for accent: TokenRowAccent) -> ImageType {
        switch accent {
        case .yield: return DesignSystem.Icons.ChartBarVertical.regular16
        case .staking: return DesignSystem.Icons.Stack.regular16
        }
    }
}

// MARK: - Configuration

private extension TokenRowShowcase {
    struct Configuration {
        var contentCase: ContentCase = .balance
        var accent: TokenRowAccent = .yield
        var rewardIsActive = true
        var rewardIsUpdating = false
        var titleAccessory: TitleAccessoryOption = .reward
        var showQuote = true
        var showCrypto = true
        var showBubble = false
        var bubbleHasIcon = true
        var bubbleHasChevron = false
        var fiatState: BalanceStateOption = .loaded
        var cryptoState: BalanceStateOption = .loaded
        var isStale = false
        var isAttributed = false
        var priceChange: PriceChangeOption = .positive
        var isPriceChangeUpdating = false
        var indicator: IndicatorOption = .none
        var compactSubtitle: CompactSubtitleOption = .balance
        var showTrailingIcon = true
        var isIconGrayscale = false
        var overflow = false

        var title: String { overflow ? "Wrapped Staked Ether Long Name" : "Bitcoin" }
        var quote: String { overflow ? "$107,840.1234567" : "$107,840" }
        var fiat: String { overflow ? "$1,583,204.9912" : "$583.00" }
        var crypto: String { overflow ? "0.00000541234567 BTC" : "0.0000054 BTC" }
        var ticker: String { overflow ? "WSTETH" : "BTC" }
        var warningText: String { overflow ? "Network is unreachable right now" : "Unreachable" }
        var noteText: String { overflow ? "No address derived yet" : "No address" }

        var rewardLabel: String {
            switch accent {
            case .yield: return overflow ? "APY 5.4712345%" : "APY 5.47%"
            case .staking: return overflow ? "APR 12.3456789%" : "APR 12.34%"
            }
        }
    }
}

// MARK: - Showcase axes

extension TokenRowShowcase {
    enum PriceChangeOption: Hashable, CaseIterable {
        case none
        case positive
        case neutral
        case negative

        func value(isUpdating: Bool) -> TokenRowPriceChange? {
            switch self {
            case .none: return nil
            case .positive: return TokenRowPriceChange(value: "2.08%", direction: .positive, isUpdating: isUpdating)
            case .neutral: return TokenRowPriceChange(value: "2.34%", direction: .neutral, isUpdating: isUpdating)
            case .negative: return TokenRowPriceChange(value: "2.30%", direction: .negative, isUpdating: isUpdating)
            }
        }
    }
}

private extension TokenRowShowcase {
    enum ContentCase: Hashable, CaseIterable {
        case balance
        case compact
        case warning
        case note
        case shimmer
    }

    enum TitleAccessoryOption: Hashable, CaseIterable {
        case none
        case reward
        case pending
    }

    enum RewardStateOption: Hashable, CaseIterable {
        case active
        case inactive
        case updating
    }

    enum BalanceStateOption: Hashable, CaseIterable {
        case loading
        case updating
        case loaded

        var label: String {
            switch self {
            case .loading: return "skeleton"
            case .updating: return "shimmer"
            case .loaded: return "loaded"
            }
        }
    }

    enum CompactSubtitleOption: Hashable, CaseIterable {
        case balance
        case message
    }

    enum IndicatorOption: Hashable, CaseIterable {
        case none
        case approveNeeded

        var value: TokenRow.BalanceIndicator? {
            switch self {
            case .none: return nil
            case .approveNeeded: return .approveNeeded
            }
        }
    }
}
#endif
