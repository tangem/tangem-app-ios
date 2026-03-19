//
//  ExpressAPIProviderResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

/// Resolves the correct `ExpressAPIProvider` for a given userId,
/// caching providers to avoid re-creation on every polling cycle.
final class ExpressAPIProviderResolver {
    private let defaultUserId: String
    private let providerFactory: (String) -> ExpressAPIProvider

    private var cache: [String: ExpressAPIProvider] = [:]

    init(
        defaultUserId: String,
        providerFactory: @escaping (String) -> ExpressAPIProvider
    ) {
        self.defaultUserId = defaultUserId
        self.providerFactory = providerFactory
    }

    /// Returns the appropriate `ExpressAPIProvider` for the given source user wallet ID.
    /// For cross-wallet swaps, the status request must use the source wallet's userId.
    func provider(for userId: String?) -> ExpressAPIProvider {
        let resolvedUserId = userId ?? defaultUserId

        if let cached = cache[resolvedUserId] {
            return cached
        }

        let provider = providerFactory(resolvedUserId)
        cache[resolvedUserId] = provider
        return provider
    }
}
