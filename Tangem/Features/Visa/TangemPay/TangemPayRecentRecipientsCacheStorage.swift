//
//  TangemPayRecentRecipientsCacheStorage.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol TangemPayRecentRecipientsCacheStorage {
    func recentRecipientIds(customerWalletId: String) -> [String]
    func recordRecipientUsage(id: String, customerWalletId: String)
}
