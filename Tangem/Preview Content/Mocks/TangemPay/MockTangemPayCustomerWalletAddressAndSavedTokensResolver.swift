//
//  MockTangemPayCustomerWalletAddressAndSavedTokensResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay

/// Hot wallets in UI tests lack the VISA derivation (`m/44'/60'/999999'/0/0`) — it appears
/// only after Tangem Pay authorization via TangemSdk, unreachable in deterministic tests.
/// Returns a synthetic address so `TangemPayManager` can proceed past `.syncNeeded`.
final class MockTangemPayCustomerWalletAddressAndSavedTokensResolver: TangemPayCustomerWalletAddressAndSavedTokensResolver {
    private let tokensRepository: TangemPayAuthorizationTokensRepository

    init(tokensRepository: TangemPayAuthorizationTokensRepository = MockTangemPayAuthorizationTokensRepository()) {
        self.tokensRepository = tokensRepository
    }

    func resolve(
        customerWalletId: String,
        keysRepository: KeysRepository
    ) -> (customerWalletAddress: String, tokens: TangemPayAuthorizationTokens)? {
        guard let tokens = tokensRepository.getToken(forCustomerWalletId: customerWalletId) else {
            return nil
        }
        return ("0x0000000000000000000000000000000000000002", tokens)
    }
}
