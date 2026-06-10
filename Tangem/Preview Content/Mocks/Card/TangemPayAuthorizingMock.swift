//
//  TangemPayAuthorizingMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemVisa
import TangemPay

class TangemPayAuthorizingMock: TangemPayAuthorizing {
    var syncNeededTitle: String = "Mock Sync Needed"

    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws(TangemPayAuthorizationError) -> TangemPayAuthorizingResponse {
        TangemPayAuthorizingResponse(
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
