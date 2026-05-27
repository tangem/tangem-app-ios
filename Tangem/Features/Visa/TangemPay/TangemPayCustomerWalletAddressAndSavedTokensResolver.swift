//
//  TangemPayCustomerWalletAddressAndSavedTokensResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayCustomerWalletAddressAndSavedTokensResolver {
    func resolve(
        customerWalletId: String,
        keysRepository: KeysRepository
    ) -> (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)?
}
