//
//  AppleSignInNonce.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation
import Security

enum AppleSignInNonce {
    /// An opaque one-time nonce: `byteCount` CSPRNG bytes, hex-encoded (2 characters per byte).
    static func randomNonceString(byteCount: Int = 32) throws(SocialAuthError) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            throw .nonceGenerationFailed(status: status)
        }

        return bytes.hexString
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).hexString
    }
}

/// Lowercase hex is part of the nonce contract: Apple echoes the request value into the
/// ID token's `nonce` claim verbatim, and the backend compares it against a lowercase digest.
private extension Sequence<UInt8> {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
