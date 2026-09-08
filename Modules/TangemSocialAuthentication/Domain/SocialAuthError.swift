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
    /// The system CSPRNG failed to produce nonce bytes.
    case nonceGenerationFailed(status: OSStatus)
    /// Any other provider failure. The wrapped error must never carry request payloads or
    /// tokens (NFR-04) — map transport errors to dedicated cases instead of wrapping them here.
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
        case .nonceGenerationFailed(let status):
            "Failed to generate a nonce (status: \(status))"
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
        case .nonceGenerationFailed:
            111001002
        case .authorizationFailed:
            111001003
        }
    }
}
