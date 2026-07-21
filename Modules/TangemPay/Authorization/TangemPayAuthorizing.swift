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

public extension TangemPayAuthorizationError {
    /// The user cancelled the card scan / authorization, as opposed to a request failure.
    var isUserCancelled: Bool {
        (underlyingError as? TangemSdkError)?.isUserCancelled ?? (underlyingError is CancellationError)
    }

    /// The HTTP status code of a server-side response failure (e.g. a 5xx on the challenge/token
    /// requests), or `nil` when the failure wasn't a server error.
    var serverErrorStatusCode: Int? {
        guard
            let apiError = underlyingError as? TangemPayAPIServiceError,
            case .serverError(let statusCode) = apiError
        else {
            return nil
        }
        return statusCode
    }
}
