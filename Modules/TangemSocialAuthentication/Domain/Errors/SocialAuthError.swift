//
//  SocialAuthError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum SocialAuthError: Error {
    /// The user dismissed the provider's sign-in UI.
    case cancelled
    /// The provider returned a credential without a usable identity token.
    case invalidCredential
    /// Any other provider failure.
    case authorizationFailed(underlying: Error)
}

// MARK: - LocalizedError

extension SocialAuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cancelled:
            "Sign-in was cancelled by the user"
        case .invalidCredential:
            "The identity provider returned an invalid credential"
        case .authorizationFailed(let underlying):
            "Authorization failed: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - UniversalError

/// Feature `111` (SocialAuthentication), subsystem `001` (provider sign-in).
extension SocialAuthError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .cancelled:
            111001000
        case .invalidCredential:
            111001001
        case .authorizationFailed:
            111001002
        }
    }
}
