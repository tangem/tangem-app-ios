//
//  TokenRow+Content.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Shared types

public struct TokenRowPriceChange: Equatable, Hashable, Sendable {
    public let value: String
    public let direction: UtilPriceChange.Direction
    public let isUpdating: Bool

    public init(value: String, direction: UtilPriceChange.Direction, isUpdating: Bool = false) {
        self.value = value
        self.direction = direction
        self.isUpdating = isUpdating
    }
}

public enum TokenRowBalanceValue: Equatable, Hashable, Sendable {
    case loading
    case updating(UtilBalance.Value)
    case loaded(UtilBalance.Value)
}

public extension TokenRowBalanceValue {
    static func updating(_ value: String) -> Self {
        TokenRowBalanceValue.updating(UtilBalance.Value.string(value))
    }

    static func loaded(_ value: String) -> Self {
        TokenRowBalanceValue.loaded(UtilBalance.Value.string(value))
    }
}

// MARK: - Content

public extension TokenRow {
    struct Icon: Hashable {
        public let info: TokenIconInfo
        public let isGrayscale: Bool

        public init(_ info: TokenIconInfo, isGrayscale: Bool = false) {
            self.info = info
            self.isGrayscale = isGrayscale
        }
    }

    struct Balance: Equatable, Hashable, Sendable {
        public let fiat: Fiat
        public let crypto: TokenRowBalanceValue?

        public init(fiat: Fiat, crypto: TokenRowBalanceValue? = nil) {
            self.fiat = fiat
            self.crypto = crypto
        }
    }

    enum BalanceIndicator: Sendable, Hashable, CaseIterable {
        case approveNeeded
    }

    struct AccessibilityIdentifiers: Equatable, Hashable, Sendable {
        public let name: String?
        public let fiatBalance: String?
        public let cryptoBalance: String?
        public let titleAccessory: String?

        public init(
            name: String? = nil,
            fiatBalance: String? = nil,
            cryptoBalance: String? = nil,
            titleAccessory: String? = nil
        ) {
            self.name = name
            self.fiatBalance = fiatBalance
            self.cryptoBalance = cryptoBalance
            self.titleAccessory = titleAccessory
        }
    }

    enum Content {
        case balance(
            icon: Icon,
            title: String,
            titleAccessory: TokenRowTitleAccessory.Model?,
            quote: String?,
            priceChange: TokenRowPriceChange?,
            balance: Balance,
            indicator: BalanceIndicator?,
            bubble: TokenRowMessageBubble.Model?,
            onTap: () -> Void
        )

        case compact(
            icon: Icon,
            title: String,
            ticker: String,
            subtitle: CompactSubtitle,
            trailingIcon: ImageType?
        )

        case warning(
            icon: TokenIconInfo,
            title: String,
            quote: String?,
            priceChange: TokenRowPriceChange?,
            text: String,
            onTap: () -> Void
        )

        case note(
            icon: TokenIconInfo,
            title: String,
            quote: String?,
            priceChange: TokenRowPriceChange?,
            text: String,
            onTap: () -> Void
        )

        case shimmer
    }

    enum CompactSubtitle: Equatable, Hashable, Sendable {
        case balance(TokenRowBalanceValue)
        case message(String)
    }

    enum Accessibility: Equatable, Hashable, Sendable {
        case combined(label: String?)
        case leaves(AccessibilityIdentifiers)
    }
}

// MARK: - Fiat balance

public extension TokenRow.Balance {
    /// Staleness rides on `loaded` alone: a skeleton means nothing was cached, so there is nothing to go stale.
    enum Fiat: Equatable, Hashable, Sendable {
        case loading
        case updating(UtilBalance.Value)
        case loaded(UtilBalance.Value, isStale: Bool = false)
    }
}

public extension TokenRow.Balance.Fiat {
    static func updating(_ value: String) -> Self {
        TokenRow.Balance.Fiat.updating(UtilBalance.Value.string(value))
    }

    static func loaded(_ value: String, isStale: Bool = false) -> Self {
        TokenRow.Balance.Fiat.loaded(UtilBalance.Value.string(value), isStale: isStale)
    }
}

// MARK: - Balance state

extension TokenRow.Balance {
    var isStale: Bool {
        fiat.isStale
    }

    var hasSkeleton: Bool {
        fiat == TokenRow.Balance.Fiat.loading || crypto == TokenRowBalanceValue.loading
    }
}

extension TokenRow.Balance.Fiat {
    var isStale: Bool {
        switch self {
        case .loaded(_, let isStale): isStale
        case .loading, .updating: false
        }
    }

    var value: TokenRowBalanceValue {
        switch self {
        case .loading: TokenRowBalanceValue.loading
        case .updating(let value): TokenRowBalanceValue.updating(value)
        case .loaded(let value, _): TokenRowBalanceValue.loaded(value)
        }
    }
}

// MARK: - Setupable

public extension TokenRow {
    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibility = .combined(label: label) }
    }

    func accessibilityIdentifiers(_ identifiers: AccessibilityIdentifiers) -> Self {
        map { $0.accessibility = .leaves(identifiers) }
    }
}
