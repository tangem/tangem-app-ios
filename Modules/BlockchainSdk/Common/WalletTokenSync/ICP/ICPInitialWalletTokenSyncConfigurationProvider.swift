//
//  ICPInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct ICPInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .internetComputer = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let icpNetworkService: ICPNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let nativeBalance = try await icpNetworkService.getBalance(address: address).async()

        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
