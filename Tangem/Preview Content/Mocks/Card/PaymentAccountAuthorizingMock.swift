//
//  PaymentAccountAuthorizingMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemPay

class PaymentAccountAuthorizingMock: PaymentAccountAuthorizing {
    var syncNeededTitle: String = "Mock Sync Needed"

    func authorize(
        customerWalletId: String,
        authorizationService: PaymentAccountAuthorizationService
    ) async throws -> PaymentAccountAuthorizingResponse {
        PaymentAccountAuthorizingResponse(
            customerWalletAddress: "",
            tokens: TangemPayAuthorizationTokens(
                accessToken: "",
                refreshToken: "",
                expiresAt: .distantFuture,
                refreshExpiresAt: .distantFuture
            ),
            derivationResult: [:]
        )
    }
}
