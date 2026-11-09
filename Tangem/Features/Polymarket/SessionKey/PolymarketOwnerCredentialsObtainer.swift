//
//  PolymarketOwnerCredentialsObtainer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

protocol PolymarketOwnerCredentialsObtaining {
    func hasCredentials() -> Bool

    func obtain(authHeaders: PolymarketCLOBAuthHeaders) async
}

struct CommonPolymarketOwnerCredentialsObtainer {
    private let userWalletId: UserWalletId
    private let clobService: PolymarketCLOBService
    private let credentialsRepository: PolymarketCredentialsRepository

    init(userWalletId: UserWalletId, clobService: PolymarketCLOBService, credentialsRepository: PolymarketCredentialsRepository) {
        self.userWalletId = userWalletId
        self.clobService = clobService
        self.credentialsRepository = credentialsRepository
    }
}

// MARK: - PolymarketOwnerCredentialsObtaining protocol conformance

extension CommonPolymarketOwnerCredentialsObtainer: PolymarketOwnerCredentialsObtaining {
    func hasCredentials() -> Bool {
        credentialsRepository.load(userWalletId: userWalletId) != nil
    }

    func obtain(authHeaders: PolymarketCLOBAuthHeaders) async {
        do {
            let credentials = try await clobService.deriveOrCreateCredentials(authHeaders: authHeaders)
            try credentialsRepository.save(credentials: credentials, userWalletId: userWalletId)
        } catch {
            PolymarketLogger.error("Failed to obtain the owner trading credentials for the session key check", error: error)
        }
    }
}

// MARK: - Deriving or creating credentials

extension PolymarketCLOBService {
    func deriveOrCreateCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        do {
            return try await deriveCredentials(authHeaders: authHeaders)
        } catch let error as PolymarketAPIError where error.isClientRefusal {
            return try await createCredentials(authHeaders: authHeaders)
        }
    }
}
