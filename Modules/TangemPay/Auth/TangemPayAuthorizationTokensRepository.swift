//
//  TangemPayAuthorizationTokensRepository.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import LocalAuthentication

public protocol TangemPayAuthorizationTokensRepository {
    func save(tokens: TangemPayAuthorizationTokens, customerWalletId: String) throws
    func deleteTokens(customerWalletId: String) throws
    func getToken(forCustomerWalletId customerWalletId: String) -> TangemPayAuthorizationTokens?
}
