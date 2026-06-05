//
//  CachingExpressAPIProviderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

/// `ExpressAPIProvider` factory that caches one instance per `(userWalletId, refcode)` pair, creating
/// each lazily on first request to avoid re-building on every polling cycle.
/// - Note: Uses an internal lock to guard the mutable cache; therefore `@unchecked Sendable` is intentional.
final class CachingExpressAPIProviderFactory: @unchecked Sendable {
    typealias Factory = (_ userWalletId: String, _ refcode: Refcode?) -> ExpressAPIProvider

    private let providerFactory: Factory
    private let cache = OSAllocatedUnfairLock<[CacheKey: ExpressAPIProvider]>(initialState: [:])

    init(providerFactory: @escaping Factory) {
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

private extension CachingExpressAPIProviderFactory {
    struct CacheKey: Hashable {
        let userWalletId: String
        let refcode: Refcode?
    }
}
