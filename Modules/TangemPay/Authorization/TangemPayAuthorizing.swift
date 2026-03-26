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
        authorizationService: TangemPayAuthorizationService,
        pendingDerivations: [Data: [DerivationPath]]
    ) async throws(TangemPayAuthorizationError) -> TangemPayAuthorizingResponse
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

public struct TangemPayAuthorizationError: Error {
    public let underlyingError: Error
    public let derivationResult: [Data: DerivedKeys]

    public init(underlyingError: Error, derivationResult: [Data: DerivedKeys]) {
        self.underlyingError = underlyingError
        self.derivationResult = derivationResult
    }
}
