//
//  TangemPayCustomerWalletAddressAndAuthorizationTokensProvider.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol TangemPayCustomerWalletAddressAndAuthorizationTokensProvider {
    func get(customerWalletId: String) -> (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)?
}
