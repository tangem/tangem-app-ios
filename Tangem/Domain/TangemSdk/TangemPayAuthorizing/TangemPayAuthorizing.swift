//
//  TangemPayAuthorizing.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk
import TangemVisa
import TangemPay

protocol TangemPayAuthorizing: TangemPayAuthorizerSyncNeededTitleProvider {
    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizingResponse
}

struct TangemPayAuthorizingResponse {
    public let customerWalletAddress: String
    public let tokens: TangemPayAuthorizationTokens
    public let derivationResult: [Data: DerivedKeys]
}
