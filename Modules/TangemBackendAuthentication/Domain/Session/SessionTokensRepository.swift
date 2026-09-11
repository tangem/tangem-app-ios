//
//  SessionTokensRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SessionTokensRepository: Sendable {
    func persist(_ tokens: SessionTokens) async throws(SessionTokensRepositoryError)
    func retrieve() async throws(SessionTokensRepositoryError) -> SessionTokens?
    func delete() async throws(SessionTokensRepositoryError)
}
