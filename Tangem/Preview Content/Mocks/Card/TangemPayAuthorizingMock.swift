//
//  TangemPayAuthorizingMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemVisa

class TangemPayAuthorizingMock: TangemPayAuthorizing {
    func authorize(authorizationService: VisaAuthorizationService) async throws -> TangemPayAuthorizingResponse {
        return TangemPayAuthorizingResponse(
            tokens: VisaAuthorizationTokens(
                accessToken: nil,
                refreshToken: "",
                authorizationType: .customerWallet
            ),
            derivationResult: [:]
        )
    }
}
