//
//  PolymarketFastTradingBannerDismissals.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol PolymarketFastTradingBannerDismissals {
    func dismissalDate(of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) -> Date?
    func setDismissalDate(_ date: Date, of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId)
    func deleteDismissals(userWalletId: UserWalletId)
}

extension PolymarketFastTradingBannerDismissals {
    func dismissalDates(userWalletId: UserWalletId) -> PolymarketFastTradingBanner.DismissalDates {
        PolymarketFastTradingBanner.DismissibleKind.allCases.reduce(into: [:]) { dates, kind in
            dates[kind] = dismissalDate(of: kind, userWalletId: userWalletId)
        }
    }
}

// MARK: - AppSettings

extension AppSettings: PolymarketFastTradingBannerDismissals {
    func dismissalDate(of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) -> Date? {
        polymarketFastTradingBannerDismissedAt[fastTradingBannerKey(kind, userWalletId: userWalletId)]
    }

    func setDismissalDate(_ date: Date, of kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) {
        polymarketFastTradingBannerDismissedAt[fastTradingBannerKey(kind, userWalletId: userWalletId)] = date
    }

    func deleteDismissals(userWalletId: UserWalletId) {
        for kind in PolymarketFastTradingBanner.DismissibleKind.allCases {
            polymarketFastTradingBannerDismissedAt[fastTradingBannerKey(kind, userWalletId: userWalletId)] = nil
        }
    }
}

// MARK: - Private implementation

private extension AppSettings {
    func fastTradingBannerKey(_ kind: PolymarketFastTradingBanner.DismissibleKind, userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.polymarketFastTradingBannerDismissedAt.rawValue + kind.rawValue)
    }
}
