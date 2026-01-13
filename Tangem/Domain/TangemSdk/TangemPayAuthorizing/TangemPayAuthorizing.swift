//
//  TangemPayAuthorizing.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay
import TangemSdk
import TangemVisa

protocol TangemPayAuthorizing: AnyObject {
    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws
}
