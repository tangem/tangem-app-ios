//
//  TangemPayCashbackCacheStorage.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayCashbackCacheStorage {
    func cachedCashbackSummary(customerWalletId: String) -> TangemPayCashbackSummaryResponse?
    func saveCachedCashbackSummary(_ summary: TangemPayCashbackSummaryResponse, customerWalletId: String)
    func clearCachedCashbackSummary(customerWalletId: String)
}
