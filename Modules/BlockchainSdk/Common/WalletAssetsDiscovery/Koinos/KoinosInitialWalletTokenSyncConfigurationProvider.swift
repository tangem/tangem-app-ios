//
//  KoinosInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct KoinosInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .koinos = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let koinosNetworkService: KoinosNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let accountInfo = try await koinosNetworkService.getInfo(address: address, koinContractId: nil).async()

        let nativeBalance = Decimal(accountInfo.koinBalance) / blockchain.decimalValue
        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
