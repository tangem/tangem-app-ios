//
//  SocialAuthAPIError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum SocialAuthAPIError: Error {
    case http(statusCode: Int, problemDetail: SocialAuthProblemDetail?)
    case connection(underlying: Error)
    case decoding(underlying: Error)
}

// MARK: - Error cases

public extension SocialAuthAPIError {
    var isRecoveryBindingNotFound: Bool {
        guard case .http(statusCode: Constants.notFoundStatusCode, problemDetail: let problemDetail?) = self else {
            return false
        }

        return problemDetail.code == Constants.recoveryBindingNotFoundCode
    }
}

// MARK: - Constants

private extension SocialAuthAPIError {
    enum Constants {
        static let notFoundStatusCode = 404
        static let recoveryBindingNotFoundCode = "RECOVERY_BINDING_NOT_FOUND"
    }
}

// MARK: - SocialAuthProblemDetail

/// Error payload
public struct SocialAuthProblemDetail: Decodable {
    /// HTTP status code.
    let status: Int

    /// Short human-readable summary.
    let title: String

    /// Human-readable explanation.
    let detail: String

    /// Machine-readable error code.
    let code: String?

    /// URI reference to this occurrence.
    let instance: String?

    /// Present when an observation trace is active.
    let traceId: String?

    /// ISO 8601 date-time, present when no trace id is available.
    let timestamp: String?

    /// Validation detail arguments, when applicable.
    let errors: [String]?
}
