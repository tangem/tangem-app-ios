//
//  MockTangemPayAuthorizationTokensRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

/// Returns synthetic non-expiring tokens for any customer wallet id.
final class MockTangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository {
    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {}

    func deleteTokens(customerWalletId: String) throws {}

    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens? {
        let farFuture = Date(timeIntervalSince1970: 9_999_999_999)
        return TangemPayAuthorizationTokens(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiresAt: farFuture,
            refreshExpiresAt: farFuture
        )
    }
}
