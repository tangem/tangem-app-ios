//
//  TangemPayAuthorizingMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemPay
import TangemVisa

class TangemPayAuthorizingMock: TangemPayAuthorizing {
    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws {}
}
