//
//  PolymarketBalanceDisplay.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct PolymarketBalanceDisplay {
    private(set) var mode: Mode = .available

    private var available: FormattedTokenBalanceType?
    private var total: FormattedTokenBalanceType?
    private var cached: FormattedTokenBalanceType.Cached?

    private let stateBuilder = LoadableBalanceViewStateBuilder()

    var canSwitchMode: Bool {
        total.map(Self.hasValue) ?? false
    }

    var state: LoadableBalanceView.State? {
        switch mode {
        case .available:
            available.map { makeState(from: withCachedFallback($0)) }
        case .total:
            total.map(makeState(from:))
        }
    }

    mutating func update(available formatted: FormattedTokenBalanceType) {
        record(formatted)
        available = formatted
    }

    mutating func update(total formatted: FormattedTokenBalanceType) {
        total = formatted
        normalizeMode()
    }

    mutating func toggleMode() {
        guard canSwitchMode else { return }

        mode = mode == .total ? .available : .total
    }
}

// MARK: - Mode

extension PolymarketBalanceDisplay {
    enum Mode {
        case available
        case total
    }
}

// MARK: - Private implementation

private extension PolymarketBalanceDisplay {
    mutating func normalizeMode() {
        if !canSwitchMode {
            mode = .available
        }
    }

    mutating func record(_ formatted: FormattedTokenBalanceType) {
        switch formatted {
        case .loaded(let balance):
            cached = .init(balance: balance, date: Date())
        case .loading(.cache(let cache)), .failure(.cache(let cache)):
            cached = cache
        case .loading(.empty), .failure(.empty):
            break
        }
    }

    func withCachedFallback(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .failure(.empty) = formatted, let cached else { return formatted }

        return .failure(.cache(cached))
    }

    func makeState(from formatted: FormattedTokenBalanceType) -> LoadableBalanceView.State {
        AttributedBalanceFormatter.decimalColored(
            stateBuilder.build(type: Self.steady(formatted), icon: .leading),
            integerPart: .init(
                font: TangemFontStyle(DesignSystem.Font.displayMediumToken),
                color: DesignSystem.Color.textPrimary
            ),
            fractionalPart: .init(
                font: TangemFontStyle(DesignSystem.Font.headingMediumToken),
                color: DesignSystem.Color.textPrimary
            )
        )
    }

    static func hasValue(_ formatted: FormattedTokenBalanceType) -> Bool {
        switch formatted {
        case .loaded: true
        case .loading(let cached), .failure(let cached): cached.isCache
        }
    }

    static func steady(_ formatted: FormattedTokenBalanceType) -> FormattedTokenBalanceType {
        guard case .loading(.cache(let cached)) = formatted else { return formatted }

        return .loaded(cached.balance)
    }
}
