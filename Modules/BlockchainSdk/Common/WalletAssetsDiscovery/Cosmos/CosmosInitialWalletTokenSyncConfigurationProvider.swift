//
//  CosmosInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CosmosInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        switch blockchain {
        case .cosmos, .terraV1, .terraV2, .sei, .gonka:
            break
        default:
            throw BlockchainSdkError.notImplemented
        }

        let cosmosNetworkService: CosmosNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let nativeBalance = try await cosmosNetworkService.nativeBalance(for: address).async()

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
