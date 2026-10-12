//
//  SocialAuthResult.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct SocialAuthResult {
    /// Social-login OIDC ID token (JWT) as raw bytes.
    public let identityTokenData: Data

    /// The raw one-time nonce.
    public let nonce: String

    public var identityToken: String {
        String(decoding: identityTokenData, as: UTF8.self)
    }
}
