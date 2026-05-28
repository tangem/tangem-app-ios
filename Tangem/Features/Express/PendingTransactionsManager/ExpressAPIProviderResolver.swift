//
//  ExpressAPIProviderResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

/// Resolves the correct `ExpressAPIProvider` for a given user wallet ID,
/// caching providers to avoid re-creation on every polling cycle.
/// - Note: No mutable state, so this type is considered to be `Sendable` by definition.
final class ExpressAPIProviderResolver: @unchecked Sendable {
    private let providerFactory: (String, Refcode?) -> ExpressAPIProvider
    private let cache = OSAllocatedUnfairLock<[CacheKey: ExpressAPIProvider]>(initialState: [:])

    init(providerFactory: @escaping (String, Refcode?) -> ExpressAPIProvider) {
        self.providerFactory = providerFactory
    }

    func provider(for userWalletId: String, refcode: Refcode?) -> ExpressAPIProvider {
        cache { cache in
            let key = CacheKey(userWalletId: userWalletId, refcode: refcode)
            if let cached = cache[key] {
                return cached
            }

            let provider = providerFactory(userWalletId, refcode)
            cache[key] = provider

            return provider
        }
    }
}

// MARK: - Auxiliary types

private extension ExpressAPIProviderResolver {
    struct CacheKey: Hashable {
        let userWalletId: String
        let refcode: Refcode?
    }
}
