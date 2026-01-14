//
//  TangemPayAuthorizationTokensRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication
import TangemVisa

protocol TangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensSaver {
    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws
    func deleteTokens(customerWalletId: String) throws
    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens?
}

// MARK: - TangemPayAuthorizationTokensSaver

extension TangemPayAuthorizationTokensRepository {
    func saveAuthorizationTokensToStorage(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws {
        try save(tokens: tokens, customerWalletId: customerWalletId)
    }
}
