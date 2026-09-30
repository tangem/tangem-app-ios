//
//  PolymarketOrderNotification.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

public enum PolymarketOrderNotification: String, Hashable, CaseIterable, Identifiable {
    case awaitingFunds
    case partialFill
    case noLiquidity
    case belowMinOrder
    case marketClosed
    case regionRestricted
    case quoteUnavailable

    public var id: String { rawValue }

    public var isBlocking: Bool {
        switch self {
        case .awaitingFunds, .partialFill: false
        case .noLiquidity, .belowMinOrder, .marketClosed, .regionRestricted, .quoteUnavailable: true
        }
    }
}

// MARK: - Copy

extension PolymarketOrderNotification {
    var title: String {
        switch self {
        case .awaitingFunds: Localization.predictionPlaceNotificationAwaitingFundsTitle
        case .partialFill: Localization.predictionPlaceNotificationPartialTitle
        case .noLiquidity: Localization.predictionPlaceNotificationNoLiquidityTitle
        case .belowMinOrder: Localization.predictionPlaceNotificationMinOrderTitle
        case .marketClosed: Localization.predictionPlaceNotificationMarketClosedTitle
        case .regionRestricted: Localization.predictionRegionRestrictionsTitle
        case .quoteUnavailable: Localization.predictionPlaceNotificationQuoteErrorTitle
        }
    }

    var message: String {
        switch self {
        case .awaitingFunds: Localization.predictionPlaceNotificationAwaitingFundsDescription
        case .partialFill: Localization.predictionPlaceNotificationPartialDescription
        case .noLiquidity: Localization.predictionPlaceNotificationNoLiquidityDescription
        case .belowMinOrder: Localization.predictionPlaceNotificationMinOrderDescription
        case .marketClosed: Localization.predictionPlaceNotificationMarketClosedDescription
        case .regionRestricted: Localization.predictionRegionRestrictionsSubtitle
        case .quoteUnavailable: Localization.predictionPlaceNotificationQuoteErrorDescription
        }
    }
}

// MARK: - Appearance

extension PolymarketOrderNotification {
    var variant: MessageBannerVariant {
        switch self {
        case .awaitingFunds: .info
        case .partialFill: .default
        case .noLiquidity, .belowMinOrder, .marketClosed, .regionRestricted, .quoteUnavailable: .error
        }
    }

    var glowRing: GlowRingAppearance? {
        switch self {
        case .awaitingFunds: nil
        case .partialFill: .warning
        case .noLiquidity, .belowMinOrder, .marketClosed, .regionRestricted, .quoteUnavailable: .error
        }
    }
}
