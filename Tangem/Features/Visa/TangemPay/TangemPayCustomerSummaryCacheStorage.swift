//
//  TangemPayCustomerSummaryCacheStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay

protocol TangemPayCustomerSummaryCacheStorage {
    func cachedCustomerSummary(userWalletId: UserWalletId) -> TangemPayCustomerSummaryResponse?
    func saveCachedCustomerSummary(_ summary: TangemPayCustomerSummaryResponse, userWalletId: UserWalletId)
    func clearCachedCustomerSummary(userWalletId: UserWalletId)
}

extension AppSettings: TangemPayCustomerSummaryCacheStorage {
    func cachedCustomerSummary(userWalletId: UserWalletId) -> TangemPayCustomerSummaryResponse? {
        guard let data = tangemPayCachedCustomerSummary[customerSummaryKey(for: userWalletId)]?.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(TangemPayCustomerSummaryResponse.self, from: data)
    }

    func saveCachedCustomerSummary(_ summary: TangemPayCustomerSummaryResponse, userWalletId: UserWalletId) {
        guard let data = try? JSONEncoder().encode(summary),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return
        }

        tangemPayCachedCustomerSummary[customerSummaryKey(for: userWalletId)] = jsonString
    }

    func clearCachedCustomerSummary(userWalletId: UserWalletId) {
        tangemPayCachedCustomerSummary[customerSummaryKey(for: userWalletId)] = nil
    }
}

private extension AppSettings {
    func customerSummaryKey(for userWalletId: UserWalletId) -> String {
        userWalletId.hashedStringValue(message: StorageType.tangemPayCachedCustomerSummary.rawValue)
    }
}
