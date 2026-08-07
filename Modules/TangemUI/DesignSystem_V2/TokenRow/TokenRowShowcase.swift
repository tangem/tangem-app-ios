//
//  TokenRowShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TokenRowShowcase: View {
    @State private var contentCase: ContentCase = .balance
    @State private var accent: TokenRowAccent = .yield
    @State private var rewardIsActive = true
    @State private var rewardIsUpdating = false
    @State private var titleAccessory: TitleAccessoryOption = .reward
    @State private var showQuote = true
    @State private var showCrypto = true
    @State private var showBubble = false
    @State private var bubbleHasIcon = true
    @State private var fiatState: BalanceStateOption = .loaded
    @State private var cryptoState: BalanceStateOption = .loaded
    @State private var isStale = false
    @State private var isMasked = false
    @State private var isAttributed = false
    @State private var isPriceChangeUpdating = false
    @State private var indicator: IndicatorOption = .none
    @State private var priceChange: PriceChangeOption = .positive
    @State private var compactSubtitle: CompactSubtitleOption = .balance
    @State private var showTrailingIcon = true
    @State private var isIconGrayscale = false

    @State private var isRowEnabled = true
    @State private var overflow = false
    @State private var isDark = false
    @State private var isRTL = false
    @State private var dynamicTypeIndex = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    @State private var tapCount = 0
    @State private var bubbleTapCount = 0
    @State private var closeCount = 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                previewSection

                contentControls

                stateControls

                environmentControls
            }
            .padding()
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        section(title: "Preview") {
            row
                .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .environment(\.isBalanceMasked, isMasked)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                .environment(\.colorScheme, isDark ? .dark : .light)

            Text("taps: \(tapCount) · bubble taps: \(bubbleTapCount) · dismissals: \(closeCount)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var row: some View {
        TokenRow(content)
            .accessibilityIdentifier("TokenRowShowcase")
            .disabled(!isRowEnabled)
    }

    private var content: TokenRow.Content {
        switch contentCase {
        case .balance:
            return TokenRow.Content.balance(
                icon: TokenRow.Icon(Self.iconInfo, isGrayscale: isIconGrayscale),
                title: title,
                titleAccessory: titleAccessoryModel,
                quote: showQuote ? quote : nil,
                priceChange: priceChange.value(isUpdating: isPriceChangeUpdating),
                balance: TokenRow.Balance(
                    fiat: fiatBalanceValue(fiatState, fiat),
                    crypto: showCrypto ? balanceValue(cryptoState, crypto) : nil
                ),
                indicator: indicator.value,
                bubble: showBubble ? bubbleModel : nil,
                onTap: { tapCount += 1 }
            )

        case .compact:
            return TokenRow.Content.compact(
                icon: TokenRow.Icon(Self.iconInfo, isGrayscale: isIconGrayscale),
                title: title,
                ticker: ticker,
                subtitle: compactSubtitleValue,
                trailingIcon: showTrailingIcon ? DesignSystem.Icons.SignEqual.regular24 : nil
            )

        case .warning:
            return TokenRow.Content.warning(
                icon: Self.iconInfo,
                title: title,
                quote: showQuote ? quote : nil,
                priceChange: priceChange.value(isUpdating: isPriceChangeUpdating),
                text: warningText,
                onTap: { tapCount += 1 }
            )

        case .note:
            return TokenRow.Content.note(
                icon: Self.iconInfo,
                title: title,
                quote: showQuote ? quote : nil,
                priceChange: priceChange.value(isUpdating: isPriceChangeUpdating),
                text: noteText,
                onTap: { tapCount += 1 }
            )

        case .shimmer:
            return TokenRow.Content.shimmer
        }
    }

    private var titleAccessoryModel: TokenRowTitleAccessory.Model? {
        switch titleAccessory {
        case .none:
            return nil

        case .reward:
            return TokenRowTitleAccessory.Model.reward(
                TokenRowTitleAccessory.Model.Reward(
                    label: rewardLabel,
                    accent: accent,
                    isActive: rewardIsActive,
                    isUpdating: rewardIsUpdating
                )
            )

        case .pending:
            return TokenRowTitleAccessory.Model.pending(accessibilityLabel: Self.pendingAccessibilityLabel)
        }
    }

    private var bubbleModel: TokenRowMessageBubble.Model {
        TokenRowMessageBubble.Model(
            text: overflow ? Self.longBubbleText : Self.bubbleText,
            accent: accent,
            icon: bubbleHasIcon ? Self.bubbleIcon(for: accent) : nil,
            onTap: { bubbleTapCount += 1 },
            onClose: {
                closeCount += 1
                withAnimation { showBubble = false }
            }
        )
    }

    private var compactSubtitleValue: TokenRow.CompactSubtitle {
        switch compactSubtitle {
        case .balance:
            return TokenRow.CompactSubtitle.balance(balanceValue(fiatState, fiat))
        case .message:
            return TokenRow.CompactSubtitle.message(warningText)
        }
    }

    private func fiatBalanceValue(_ state: BalanceStateOption, _ string: String) -> TokenRow.Balance.Fiat {
        switch state {
        case .loading:
            return TokenRow.Balance.Fiat.loading
        case .updating:
            return TokenRow.Balance.Fiat.updating(balanceText(string))
        case .loaded:
            return TokenRow.Balance.Fiat.loaded(balanceText(string), isStale: isStale)
        }
    }

    private func balanceValue(_ state: BalanceStateOption, _ string: String) -> TokenRowBalanceValue {
        switch state {
        case .loading:
            return TokenRowBalanceValue.loading
        case .updating:
            return TokenRowBalanceValue.updating(balanceText(string))
        case .loaded:
            return TokenRowBalanceValue.loaded(balanceText(string))
        }
    }

    private func balanceText(_ string: String) -> UtilBalance.Value {
        guard isAttributed else {
            return UtilBalance.Value.string(string)
        }

        var attributed = AttributedString(string)

        if let separator = attributed.range(of: Locale.current.decimalSeparator ?? ".") {
            attributed[separator.lowerBound ..< attributed.endIndex].foregroundColor = DesignSystem.Color.textSecondary
        }

        return UtilBalance.Value.attributed(attributed)
    }

    // MARK: - Controls

    private var contentControls: some View {
        section(title: "Content") {
            picker(title: "case", cases: ContentCase.allCases, binding: $contentCase)

            if contentCase == .balance {
                picker(title: "title accessory", cases: TitleAccessoryOption.allCases, binding: $titleAccessory)

                if titleAccessory == .reward {
                    Toggle("reward is active", isOn: $rewardIsActive)
                    Toggle("reward is updating", isOn: $rewardIsUpdating)
                }

                Toggle("crypto balance", isOn: $showCrypto)

                if showCrypto {
                    picker(title: "crypto balance state", cases: BalanceStateOption.allCases, binding: $cryptoState)
                }

                Toggle("message bubble", isOn: $showBubble)

                if showBubble {
                    Toggle("bubble icon", isOn: $bubbleHasIcon)
                }

                if titleAccessory == .reward || showBubble {
                    picker(title: "accent", cases: TokenRowAccent.allCases, binding: $accent)
                }

                if fiatState == .loaded {
                    Toggle("stale balance", isOn: $isStale)
                }

                picker(title: "balance indicator", cases: IndicatorOption.allCases, binding: $indicator)
            }

            if contentCase == .compact {
                picker(title: "subtitle", cases: CompactSubtitleOption.allCases, binding: $compactSubtitle)
                Toggle("trailing icon", isOn: $showTrailingIcon)
            }

            if contentCase == .balance || contentCase == .compact {
                Toggle("grayscale icon", isOn: $isIconGrayscale)
            }

            if contentCase == .balance || (contentCase == .compact && compactSubtitle == .balance) {
                Toggle("attributed balances", isOn: $isAttributed)
                picker(title: "fiat balance", cases: BalanceStateOption.allCases, binding: $fiatState)
            }

            if contentCase != .compact, contentCase != .shimmer {
                Toggle("quote", isOn: $showQuote)
                picker(title: "price change", cases: PriceChangeOption.allCases, binding: $priceChange)

                if priceChange != PriceChangeOption.none {
                    Toggle("updating price change", isOn: $isPriceChangeUpdating)
                }
            }
        }
    }

    @ViewBuilder
    private var stateControls: some View {
        if contentCase != .shimmer {
            section(title: "State") {
                Toggle("enabled", isOn: $isRowEnabled)
                Toggle("overflowing text", isOn: $overflow)
            }
        }
    }

    private var environmentControls: some View {
        section(title: "Environment (row only)") {
            Stepper(
                "Dynamic Type: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
            Toggle("masked balances", isOn: $isMasked)
            Toggle("dark theme", isOn: $isDark)
            Toggle("right-to-left", isOn: $isRTL)
        }
    }

    // MARK: - Samples

    private var title: String { overflow ? "Wrapped Staked Ether Long Name" : "Bitcoin" }
    private var quote: String { overflow ? "$107,840.1234567" : "$107,840" }
    private var fiat: String { overflow ? "$1,583,204.9912" : "$583.00" }
    private var crypto: String { overflow ? "0.00000541234567 BTC" : "0.0000054 BTC" }
    private var ticker: String { overflow ? "WSTETH" : "BTC" }
    private var warningText: String { overflow ? "Network is unreachable right now" : "Unreachable" }
    private var noteText: String { overflow ? "No address derived yet" : "No address" }

    private var rewardLabel: String {
        switch accent {
        case .yield: return overflow ? "APY 5.4712345%" : "APY 5.47%"
        case .staking: return overflow ? "APR 12.3456789%" : "APR 12.34%"
        }
    }

    private static let pendingAccessibilityLabel = "Transaction in progress"

    private static let bubbleText = "Enable 5.47% APY on your balance"
    private static let longBubbleText = "Enable 5.47% APY on your balance and start earning rewards every single day"

    static let iconInfo = TokenIconInfo(
        name: "Bitcoin",
        blockchainIconAsset: Tokens.bitcoinFill,
        imageURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/bitcoin.png"),
        isCustom: false,
        customTokenColor: nil
    )

    static func bubbleIcon(for accent: TokenRowAccent) -> ImageType {
        switch accent {
        case .yield: return DesignSystem.Icons.ChartBarVertical.regular16
        case .staking: return DesignSystem.Icons.Stack.regular16
        }
    }

    // MARK: - Helpers

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .font(.callout)
    }

    private func picker<Value: Hashable & TokenRowShowcaseLabeled>(
        title: String,
        cases: [Value],
        binding: Binding<Value>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(value.showcaseLabel).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Showcase axes

protocol TokenRowShowcaseLabeled {
    var showcaseLabel: String { get }
}

extension TokenRowShowcase {
    enum ContentCase: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case balance
        case compact
        case warning
        case note
        case shimmer

        var showcaseLabel: String {
            switch self {
            case .balance: return "balance"
            case .compact: return "compact"
            case .warning: return "warning"
            case .note: return "note"
            case .shimmer: return "shimmer"
            }
        }
    }

    enum TitleAccessoryOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case none
        case reward
        case pending

        var showcaseLabel: String {
            switch self {
            case .none: return "none"
            case .reward: return "reward"
            case .pending: return "pending"
            }
        }
    }

    enum BalanceStateOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case loading
        case updating
        case loaded

        var showcaseLabel: String {
            switch self {
            case .loading: return "skeleton"
            case .updating: return "shimmer"
            case .loaded: return "loaded"
            }
        }
    }

    enum CompactSubtitleOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case balance
        case message

        var showcaseLabel: String {
            switch self {
            case .balance: return "balance"
            case .message: return "message"
            }
        }
    }

    enum IndicatorOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case none
        case approveNeeded

        var value: TokenRow.BalanceIndicator? {
            switch self {
            case .none: return nil
            case .approveNeeded: return .approveNeeded
            }
        }

        var showcaseLabel: String {
            switch self {
            case .none: return "none"
            case .approveNeeded: return "approve needed"
            }
        }
    }

    enum PriceChangeOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
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

        var showcaseLabel: String {
            switch self {
            case .none: return "none"
            case .positive: return "up"
            case .neutral: return "flat"
            case .negative: return "down"
            }
        }
    }
}

extension TokenRowAccent: TokenRowShowcaseLabeled {
    var showcaseLabel: String {
        switch self {
        case .yield: return "yield"
        case .staking: return "staking"
        }
    }
}
