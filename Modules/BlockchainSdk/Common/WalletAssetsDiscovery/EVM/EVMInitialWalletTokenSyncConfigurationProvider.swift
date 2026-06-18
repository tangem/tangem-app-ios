//
//  EVMInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct EVMInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard blockchain.isEvm else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService: EthereumNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let nativeBalance = try await networkService.getBalance(address).async()

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
