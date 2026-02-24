//
//  TangemTokenRowViewData.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public struct TangemTokenRowViewData: Identifiable {
    public let id: AnyHashable
    public let tokenIconInfo: TokenIconInfo
    public let name: String
    public let badge: Badge?
    public let content: ContentState
    public let hasMonochromeIcon: Bool
    public let accessibilityIdentifiers: AccessibilityIdentifiers?

    public init(
        id: AnyHashable,
        tokenIconInfo: TokenIconInfo,
        name: String,
        badge: Badge?,
        content: ContentState,
        hasMonochromeIcon: Bool,
        accessibilityIdentifiers: AccessibilityIdentifiers? = nil
    ) {
        self.id = id
        self.tokenIconInfo = tokenIconInfo
        self.name = name
        self.badge = badge
        self.content = content
        self.hasMonochromeIcon = hasMonochromeIcon
        self.accessibilityIdentifiers = accessibilityIdentifiers
    }
}

// MARK: - ContentState

public extension TangemTokenRowViewData {
    enum ContentState {
        /// Full content with balances - normal token display
        case loading(cached: CachedContent?)

        /// Full content loaded
        case loaded(LoadedContent)

        /// Error state - shows error message instead of balances
        case error(message: String)

        /// Compact state - just price, no balances (e.g., for drag/reorder UI)
        case compact(price: String?)
    }
}

// MARK: - CachedContent

public extension TangemTokenRowViewData {
    /// Cached values shown during loading with shimmer
    struct CachedContent {
        public let fiatBalance: String?
        public let cryptoBalance: String?
        public let price: String?

        public init(fiatBalance: String?, cryptoBalance: String?, price: String?) {
            self.fiatBalance = fiatBalance
            self.cryptoBalance = cryptoBalance
            self.price = price
        }
    }
}

// MARK: - LoadedContent

public extension TangemTokenRowViewData {
    /// Full loaded content
    struct LoadedContent {
        public let balances: Balances
        public let priceInfo: PriceInfo?

        public init(balances: Balances, priceInfo: PriceInfo?) {
            self.balances = balances
            self.priceInfo = priceInfo
        }
    }
}

// MARK: - Balances

public extension TangemTokenRowViewData {
    /// Balance values - always come together
    struct Balances {
        public let fiat: BalanceValue
        public let crypto: BalanceValue

        public init(fiat: BalanceValue, crypto: BalanceValue) {
            self.fiat = fiat
            self.crypto = crypto
        }
    }

    enum BalanceValue {
        case value(String)
        case failed(cached: String)
    }
}

// MARK: - PriceInfo

public extension TangemTokenRowViewData {
    /// Price and change - logically coupled
    struct PriceInfo {
        public let price: String
        public let change: PriceChange?

        public init(price: String, change: PriceChange?) {
            self.price = price
            self.change = change
        }
    }

    struct PriceChange {
        public let type: PriceChangeView.ChangeType
        public let text: String

        public init(type: PriceChangeView.ChangeType, text: String) {
            self.type = type
            self.text = text
        }

        public static func positive(_ text: String) -> PriceChange {
            PriceChange(type: .positive, text: text)
        }

        public static func neutral(_ text: String) -> PriceChange {
            PriceChange(type: .neutral, text: text)
        }

        public static func negative(_ text: String) -> PriceChange {
            PriceChange(type: .negative, text: text)
        }
    }
}

// MARK: - Badge

public extension TangemTokenRowViewData {
    enum Badge {
        case pendingTransaction
        case rewards(RewardsInfo)
    }

    struct RewardsInfo {
        public let value: String
        public let isActive: Bool
        public let isUpdating: Bool

        public init(value: String, isActive: Bool, isUpdating: Bool) {
            self.value = value
            self.isActive = isActive
            self.isUpdating = isUpdating
        }
    }
}

// MARK: - AccessibilityIdentifiers

public extension TangemTokenRowViewData {
    struct AccessibilityIdentifiers {
        public let tokenName: String?
        public let fiatBalance: String?
        public let cryptoBalance: String?
        public let rewardsBadge: String?

        public init(
            tokenName: String? = nil,
            fiatBalance: String? = nil,
            cryptoBalance: String? = nil,
            rewardsBadge: String? = nil
        ) {
            self.tokenName = tokenName
            self.fiatBalance = fiatBalance
            self.cryptoBalance = cryptoBalance
            self.rewardsBadge = rewardsBadge
        }
    }
}
