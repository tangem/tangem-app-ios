//
//  XRPAddressResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct XRPAddressResolver {
    private let networkService: XRPNetworkService

    init(networkService: XRPNetworkService) {
        self.networkService = networkService
    }
}

// MARK: - AddressResolver

extension XRPAddressResolver: AddressResolver {
    func requiresResolution(address: String) -> Bool { true }

    func resolve(_ address: String) async throws -> AddressResolverResult {
        let requiresDestinationTag = try await networkService.checkAccountDestinationTag(account: address).async()
        return AddressResolverResult(resolved: address, requiresDestinationTag: requiresDestinationTag)
    }
}
