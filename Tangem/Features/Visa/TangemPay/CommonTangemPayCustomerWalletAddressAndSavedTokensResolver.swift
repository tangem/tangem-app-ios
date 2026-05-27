//
//  CommonTangemPayCustomerWalletAddressAndSavedTokensResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

final class CommonTangemPayCustomerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver {
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    func resolve(
        customerWalletId: String,
        keysRepository: KeysRepository
    ) -> (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)? {
        guard let walletPublicKey = TangemPayUtilities.getKey(from: keysRepository),
              let customerWalletAddress = try? TangemPayUtilities.makeAddress(using: walletPublicKey),
              // If there was no refreshToken saved - means user never got tangem pay offer
              let tokens = tangemPayAuthorizationTokensRepository.getToken(forCustomerWalletId: customerWalletId)
        else {
            return nil
        }

        return (customerWalletAddress, tokens)
    }
}
