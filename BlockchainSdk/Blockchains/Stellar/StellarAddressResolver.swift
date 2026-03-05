//
//  StellarAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct StellarAddressResolver {
    private let networkService: StellarNetworkService

    init(networkService: StellarNetworkService) {
        self.networkService = networkService
    }
}

// MARK: - AddressResolver

extension StellarAddressResolver: AddressResolver {
    func requiresResolution(address: String) -> Bool { true }

    func resolve(_ address: String) async throws -> AddressResolverResult {
        let requiresDestinationTag = try await networkService.checkIsMemoRequired(for: address).async()
        return AddressResolverResult(resolved: address, requiresDestinationTag: requiresDestinationTag)
    }
}
