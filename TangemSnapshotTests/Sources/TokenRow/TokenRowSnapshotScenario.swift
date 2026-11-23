//
//  TokenRowSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum TokenRowSnapshotScenario: String, SnapshotScenario {
    case balance
    case balanceStates
    case network
    case networkRTL
    case networkLargeText
    case messageBubble
    case compact
    case messages
    case overflow
    case masked

    var layoutDirection: LayoutDirection {
        self == .networkRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        self == .networkLargeText ? .xxxLarge : .large
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        Group {
            switch self {
            case .balance:
                SnapshotGrid(BalanceSample.allCases, columns: 2) { balanceSample($0) }
            case .balanceStates:
                SnapshotGrid(balanceStateCases, columns: 3) { sample in
                    balanceRow(balance: TokenRow.Balance(fiat: fiat(sample.fiat), crypto: crypto(sample.crypto)))
                }
            case .network, .networkRTL, .networkLargeText:
                SnapshotGrid(networkCases, columns: 2) { sample in
                    networkRow(titleAccessory: sample.accessory.model, bubble: sample.hasBubble ? bubble(.pending) : nil)
                }
            case .messageBubble:
                SnapshotGrid(BubbleSample.allCases, columns: 1) { sample in
                    balanceRow(titleAccessory: nil, bubble: bubble(sample))
                }
            case .compact:
                SnapshotGrid(compactCases, columns: 2) { sample in
                    compactRow(subtitle: sample.subtitle, trailingIcon: sample.hasTrailingIcon ? DesignSystem.Icons.SignEqual.regular24 : nil)
                }
            case .messages:
                VStack(spacing: 16) {
                    warningRow(title: "Bitcoin", text: "Unreachable")
                    noteRow(title: "Bitcoin", text: "No address")
                    shimmerRow
                }
            case .overflow:
                VStack(spacing: 16) {
                    overflowRows
                }
            case .masked:
                VStack(spacing: 16) {
                    balanceRow()
                    networkRow()
                    compactRow(subtitle: .balance(.loaded("$583.00")), trailingIcon: nil)
                }
                .environment(\.isBalanceMasked, true)
            }
        }
        .environment(\.isShimmerAnimationPaused, true)
    }
}

// MARK: - Samples

private extension TokenRowSnapshotScenario {
    enum BalanceSample: CaseIterable, Hashable {
        case yieldReward
        case stakingReward
        case inactiveReward
        case updatingReward
        case pending
        case plain
        case approveNeeded
        case stale
    }

    enum BalanceState: CaseIterable, Hashable {
        case loading
        case updating
        case loaded
    }

    enum AccessorySample: CaseIterable, Hashable {
        case none
        case reward
        case pending

        var model: TokenRowTitleAccessory.Model? {
            switch self {
            case .none: nil
            case .reward: TokenRowSnapshotScenario.reward(accent: .yield, isActive: true)
            case .pending: .pending()
            }
        }
    }

    enum BubbleSample: CaseIterable, Hashable {
        case yield
        case staking
        case pending
    }

    var balanceStateCases: [(fiat: BalanceState, crypto: BalanceState)] {
        BalanceState.allCases.flatMap { fiat in
            BalanceState.allCases.map { (fiat, $0) }
        }
    }

    var networkCases: [(accessory: AccessorySample, hasBubble: Bool)] {
        AccessorySample.allCases.flatMap { accessory in
            [false, true].map { (accessory, $0) }
        }
    }

    var compactCases: [(subtitle: TokenRow.CompactSubtitle, hasTrailingIcon: Bool)] {
        [TokenRow.CompactSubtitle.balance(.loaded("$583.00")), .message("Unreachable")].flatMap { subtitle in
            [true, false].map { (subtitle, $0) }
        }
    }
}

// MARK: - Rows

@MainActor
private extension TokenRowSnapshotScenario {
    static let rowWidth: CGFloat = 343

    @ViewBuilder
    func balanceSample(_ sample: BalanceSample) -> some View {
        switch sample {
        case .yieldReward:
            balanceRow()
        case .stakingReward:
            balanceRow(
                titleAccessory: Self.reward(accent: .staking, isActive: true),
                priceChange: TokenRowPriceChange(value: "2.30%", direction: .negative)
            )
        case .inactiveReward:
            balanceRow(
                titleAccessory: Self.reward(accent: .yield, isActive: false),
                priceChange: TokenRowPriceChange(value: "2.34%", direction: .neutral)
            )
        case .updatingReward:
            balanceRow(titleAccessory: Self.reward(accent: .yield, isActive: true, isUpdating: true))
        case .pending:
            balanceRow(titleAccessory: .pending())
        case .plain:
            balanceRow(titleAccessory: nil, quote: nil, priceChange: nil, balance: TokenRow.Balance(fiat: .loaded("$583.00")))
        case .approveNeeded:
            balanceRow(indicator: .approveNeeded)
        case .stale:
            balanceRow(balance: TokenRow.Balance(fiat: .loaded("$583.00", isStale: true), crypto: .loaded("0.0000054 BTC")))
        }
    }

    @ViewBuilder
    var overflowRows: some View {
        let title = "Wrapped Staked Ether Long Name"
        let balance = TokenRow.Balance(fiat: .loaded("$1,583,204.9912"), crypto: .loaded("0.00000541234567 BTC"))

        balanceRow(
            title: title,
            titleAccessory: Self.reward(accent: .yield, isActive: true, label: "APY 5.4712345%"),
            quote: "$107,840.1234567",
            balance: balance,
            bubble: bubble(.yield, text: "Enable 5.47% APY on your balance and start earning rewards every single day")
        )
        networkRow(
            title: title,
            network: "Polygon zkEVM Cardona Testnet network",
            balance: balance,
            bubble: bubble(.pending, text: "Review and sign the operation before the other members can complete it")
        )
        compactRow(title: title, ticker: "WSTETH", subtitle: .balance(.loaded("$1,583,204.9912")), trailingIcon: DesignSystem.Icons.SignEqual.regular24)
        warningRow(title: title, text: "Network is unreachable right now")
        noteRow(title: title, text: "No address derived yet")
    }

    func balanceRow(
        title: String = "Bitcoin",
        titleAccessory: TokenRowTitleAccessory.Model? = TokenRowSnapshotScenario.reward(accent: .yield, isActive: true),
        quote: String? = "$107,840",
        priceChange: TokenRowPriceChange? = TokenRowPriceChange(value: "2.08%", direction: .positive),
        balance: TokenRow.Balance = TokenRowSnapshotScenario.loadedBalance,
        indicator: TokenRow.BalanceIndicator? = nil,
        bubble: TokenRowMessageBubble.Model? = nil
    ) -> some View {
        TokenRow(
            .balance(
                icon: TokenRow.Icon(Self.iconInfo),
                title: title,
                titleAccessory: titleAccessory,
                quote: quote,
                priceChange: priceChange,
                balance: balance,
                indicator: indicator,
                bubble: bubble,
                onTap: {}
            )
        )
        .frame(width: Self.rowWidth)
    }

    func networkRow(
        title: String = "Bitcoin",
        titleAccessory: TokenRowTitleAccessory.Model? = nil,
        network: String = "Bitcoin network",
        balance: TokenRow.Balance = TokenRowSnapshotScenario.loadedBalance,
        bubble: TokenRowMessageBubble.Model? = nil
    ) -> some View {
        TokenRow(
            .network(
                icon: TokenRow.Icon(Self.iconInfo),
                title: title,
                titleAccessory: titleAccessory,
                network: network,
                balance: balance,
                indicator: nil,
                bubble: bubble,
                onTap: {}
            )
        )
        .frame(width: Self.rowWidth)
    }

    func compactRow(
        title: String = "Bitcoin",
        ticker: String = "BTC",
        subtitle: TokenRow.CompactSubtitle,
        trailingIcon: ImageType?
    ) -> some View {
        TokenRow(
            .compact(
                icon: TokenRow.Icon(Self.iconInfo),
                title: title,
                ticker: ticker,
                subtitle: subtitle,
                trailingIcon: trailingIcon
            )
        )
        .frame(width: Self.rowWidth)
    }

    func warningRow(title: String, text: String) -> some View {
        TokenRow(
            .warning(
                icon: Self.iconInfo,
                title: title,
                quote: "$107,840",
                priceChange: TokenRowPriceChange(value: "2.08%", direction: .positive),
                text: text,
                onTap: {}
            )
        )
        .frame(width: Self.rowWidth)
    }

    func noteRow(title: String, text: String) -> some View {
        TokenRow(
            .note(
                icon: Self.iconInfo,
                title: title,
                quote: "$107,840",
                priceChange: TokenRowPriceChange(value: "2.08%", direction: .positive),
                text: text,
                onTap: {}
            )
        )
        .frame(width: Self.rowWidth)
    }

    var shimmerRow: some View {
        TokenRow(.shimmer)
            .frame(width: Self.rowWidth)
    }
}

// MARK: - Fixtures

private extension TokenRowSnapshotScenario {
    static var iconInfo: TokenIconInfo {
        TokenIconInfo(
            name: "Bitcoin",
            blockchainIconAsset: Tokens.bitcoinFill,
            imageURL: nil,
            isCustom: false,
            customTokenColor: nil
        )
    }

    static var loadedBalance: TokenRow.Balance {
        TokenRow.Balance(fiat: .loaded("$583.00"), crypto: .loaded("0.0000054 BTC"))
    }

    static func reward(
        accent: TokenRowAccent,
        isActive: Bool,
        isUpdating: Bool = false,
        label: String? = nil
    ) -> TokenRowTitleAccessory.Model {
        .reward(
            TokenRowTitleAccessory.Model.Reward(
                label: label ?? (accent == .yield ? "APY 5.47%" : "APR 12.34%"),
                accent: accent,
                isActive: isActive,
                isUpdating: isUpdating
            )
        )
    }

    func fiat(_ state: BalanceState) -> TokenRow.Balance.Fiat {
        switch state {
        case .loading: .loading
        case .updating: .updating("$583.00")
        case .loaded: .loaded("$583.00")
        }
    }

    func crypto(_ state: BalanceState) -> TokenRowValue {
        switch state {
        case .loading: .loading
        case .updating: .updating("0.0000054 BTC")
        case .loaded: .loaded("0.0000054 BTC")
        }
    }

    func bubble(_ sample: BubbleSample, text: String? = nil) -> TokenRowMessageBubble.Model {
        switch sample {
        case .yield:
            TokenRowMessageBubble.Model(
                text: text ?? "Enable 5.47% APY on your balance",
                variant: .success,
                icon: DesignSystem.Icons.ChartLineVertical.regular16,
                trailingAccessory: .close(action: {}),
                onTap: {}
            )
        case .staking:
            TokenRowMessageBubble.Model(
                text: text ?? "Enable 5.47% APR on your balance",
                variant: .info,
                icon: DesignSystem.Icons.Stack.regular16,
                trailingAccessory: .close(action: {}),
                onTap: {}
            )
        case .pending:
            TokenRowMessageBubble.Model(
                text: text ?? "Review and sign the operation",
                variant: .warning,
                icon: DesignSystem.Icons.Clock.regular16,
                trailingAccessory: .chevron,
                onTap: {}
            )
        }
    }
}
