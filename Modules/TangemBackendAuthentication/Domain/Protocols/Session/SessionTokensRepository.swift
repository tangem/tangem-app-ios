//
//  SessionTokensRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A `package` access level due to its use in the `TangemBackendAuthenticationDebugSupport` module.
package protocol SessionTokensRepository: Sendable {
    func persist(tokens: SessionTokens) async throws(SessionTokensRepositoryError)
    func retrieve() async throws(SessionTokensRepositoryError) -> SessionTokens?
    func delete() async throws(SessionTokensRepositoryError)
}
