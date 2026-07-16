//
//  TezosInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TezosInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .tezos = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let tezosNetworkService: TezosNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let tezosAddress = try await tezosNetworkService.getInfo(address: address).async()
        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: tezosAddress.balance, tokens: [])
    }
}
