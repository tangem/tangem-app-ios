//
//  PaymentAccountAuthorizing.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol PaymentAccountAuthorizing: PaymentAccountAuthorizerSyncNeededTitleProvider {
    func authorize(
        customerWalletId: String,
        authorizationService: PaymentAccountAuthorizationService
    ) async throws -> PaymentAccountAuthorizingResponse
}

public struct PaymentAccountAuthorizingResponse {
    public let customerWalletAddress: String
    public let tokens: TangemPayAuthorizationTokens
    public let derivationResult: [Data: DerivedKeys]

    public init(customerWalletAddress: String, tokens: TangemPayAuthorizationTokens, derivationResult: [Data: DerivedKeys]) {
        self.customerWalletAddress = customerWalletAddress
        self.tokens = tokens
        self.derivationResult = derivationResult
    }
}
