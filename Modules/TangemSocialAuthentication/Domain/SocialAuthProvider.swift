//
//  SocialAuthProvider.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public protocol SocialAuthProvider {
    func signIn() async throws(SocialAuthError) -> SocialAuthResult
}
