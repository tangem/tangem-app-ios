//
//  PolymarketSessionCredentialsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

struct PolymarketSessionCredentials: Hashable, Sendable {
    let sessionKeyAddress: String
    let credentials: PolymarketL2Credentials
}

protocol PolymarketSessionCredentialsProviding {
    func credentials() async throws -> PolymarketSessionCredentials

    func reset()
}

final class CommonPolymarketSessionCredentialsProvider {
    private let userWalletId: UserWalletId
    private let keyStore: PolymarketSessionKeyStore
    private let clobService: PolymarketCLOBService
    private let now: () -> Date
    private let cache = OSAllocatedUnfairLock(initialState: Cache())

    init(
        userWalletId: UserWalletId,
        keyStore: PolymarketSessionKeyStore,
        clobService: PolymarketCLOBService,
        now: @escaping () -> Date = Date.init
    ) {
        self.userWalletId = userWalletId
        self.keyStore = keyStore
        self.clobService = clobService
        self.now = now
    }
}

// MARK: - PolymarketSessionCredentialsProviding protocol conformance

extension CommonPolymarketSessionCredentialsProvider: PolymarketSessionCredentialsProviding {
    func credentials() async throws -> PolymarketSessionCredentials {
        guard let sessionKeyAddress = try keyStore.heldAddress(for: userWalletId) else {
            throw CommonPolymarketSessionKeyStore.KeyError.keyMissing
        }

        let (cached, generation) = cache.withLock { ($0.credentials, $0.generation) }

        if let cached, cached.sessionKeyAddress == sessionKeyAddress {
            return cached
        }

        let authHeaders = try makeAuthHeaders(sessionKeyAddress: sessionKeyAddress)
        let credentials = try await clobService.deriveOrCreateCredentials(authHeaders: authHeaders)
        let sessionCredentials = PolymarketSessionCredentials(sessionKeyAddress: sessionKeyAddress, credentials: credentials)

        cache.withLock { cache in
            guard cache.generation == generation else { return }

            cache.credentials = sessionCredentials
        }

        return sessionCredentials
    }

    func reset() {
        cache.withLock { cache in
            cache.credentials = nil
            cache.generation += 1
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketSessionCredentialsProvider {
    struct Cache {
        var credentials: PolymarketSessionCredentials?
        var generation = 0
    }

    func makeAuthHeaders(sessionKeyAddress: String) throws -> PolymarketCLOBAuthHeaders {
        let timestamp = String(Int(now().timeIntervalSince1970))
        let digest = PolymarketClobAuth.digest(ownerAddress: sessionKeyAddress, timestamp: timestamp)
        let signature = try keyStore.sign(hash: digest, for: userWalletId)

        return PolymarketCLOBAuthHeaders(
            ownerAddress: sessionKeyAddress,
            signature: signature,
            timestamp: timestamp,
            nonce: PolymarketClobAuth.nonce
        )
    }
}
