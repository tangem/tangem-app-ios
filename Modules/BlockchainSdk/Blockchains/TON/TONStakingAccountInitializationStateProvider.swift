//
//  TONStakingAccountInitializationStateProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class TONStakingAccountInitializationStateProvider {
    private let address: String
    private let networkService: TONNetworkService

    init(address: String, networkService: TONNetworkService) {
        self.address = address
        self.networkService = networkService
    }

    func isAccountInitialized() async throws -> Bool {
        let result = try await networkService.getInfo(address: address, tokens: []).async()
        return result.isAvailable
    }
}
