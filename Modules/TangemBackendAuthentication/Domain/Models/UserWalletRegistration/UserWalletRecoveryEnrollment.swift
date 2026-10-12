//
//  UserWalletRecoveryEnrollment.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Enrolls a user wallet into backend-assisted recovery as part of its registration.
/// Ties the wallet to the user's identity, confirmed by an external identity provider,
/// and hands the backend an encrypted recovery key.
public struct UserWalletRecoveryEnrollment: Equatable, Sendable {
    /// Social-login OIDC ID token.
    public let providerIdToken: String

    /// Base64 of the social backup recovery key `K`, encrypted with the KMS recovery public key.
    public let encryptedRecoveryKey: String

    public init(providerIdToken: String, encryptedRecoveryKey: String) {
        self.providerIdToken = providerIdToken
        self.encryptedRecoveryKey = encryptedRecoveryKey
    }
}
