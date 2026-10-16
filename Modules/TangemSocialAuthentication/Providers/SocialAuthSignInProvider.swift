//
//  SocialAuthSignInProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol SocialAuthSignInProvider {
    /// Runs the provider's sign-in flow with a server-issued nonce and returns the identity credentials.
    func signIn(nonce: String) async throws(SocialAuthError) -> SocialAuthCredentials
}
