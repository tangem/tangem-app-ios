//
//  ExpressAPIProviderResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Resolves the correct `ExpressAPIProvider` for a given user wallet ID,
/// caching providers to avoid re-creation on every polling cycle.
final class ExpressAPIProviderResolver {
    private let providerFactory: (String, Refcode?) -> ExpressAPIProvider

    private let queue = DispatchQueue(label: "com.tangem.ExpressAPIProviderResolver")
    private var cache: [String: CacheEntry] = [:]

    init(providerFactory: @escaping (String, Refcode?) -> ExpressAPIProvider) {
        self.providerFactory = providerFactory
    }

    func provider(for userWalletId: String, refcode: Refcode?) -> ExpressAPIProvider {
        queue.sync {
            if let cached = cache[userWalletId], cached.refcode == refcode {
                return cached.provider
            }

            let provider = providerFactory(userWalletId, refcode)
            cache[userWalletId] = CacheEntry(provider: provider, refcode: refcode)
            return provider
        }
    }
}

private extension ExpressAPIProviderResolver {
    struct CacheEntry {
        let provider: ExpressAPIProvider
        let refcode: Refcode?
    }
}
