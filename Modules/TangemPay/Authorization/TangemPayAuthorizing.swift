//
//  TangemPayAuthorizing.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol TangemPayAuthorizing: TangemPayAuthorizerSyncNeededTitleProvider {
    func authorize(
        customerWalletId: String,
        authorizationService: TangemPayAuthorizationService
    ) async throws -> TangemPayAuthorizingResponse
}

public struct TangemPayAuthorizingResponse {
    public let customerWalletAddress: String
    public let tokens: TangemPayAuthorizationTokens
    public let derivationResult: [Data: DerivedKeys]

    public init(customerWalletAddress: String, tokens: TangemPayAuthorizationTokens, derivationResult: [Data: DerivedKeys]) {
        self.customerWalletAddress = customerWalletAddress
        self.tokens = tokens
        self.derivationResult = derivationResult
    }
}
