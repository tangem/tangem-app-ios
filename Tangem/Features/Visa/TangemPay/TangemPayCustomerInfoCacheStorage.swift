//
//  TangemPayCustomerInfoCacheStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayCustomerInfoCacheStorage {
    func cachedCustomerInfo(customerWalletId: String) -> VisaCustomerInfoResponse?
    func saveCachedCustomerInfo(_ customerInfo: VisaCustomerInfoResponse, customerWalletId: String)
    func clearCachedCustomerInfo(customerWalletId: String)
}
