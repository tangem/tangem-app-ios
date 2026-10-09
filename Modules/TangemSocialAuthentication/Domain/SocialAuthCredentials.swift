//
//  SocialAuthCredentials.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct SocialAuthCredentials {
    /// Social-login OIDC ID token.
    public let identityTokenData: Data

    /// Server-issued one-time nonce.
    public let nonce: String

    public var identityToken: String {
        String(decoding: identityTokenData, as: UTF8.self)
    }
}
