//
//  VeChainInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct VeChainInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .veChain = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let veChainNetworkService: VeChainNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

        let accountInfo = try await veChainNetworkService.getAccountInfo(address: address).async()
        let nativeBalance = accountInfo.amount.value

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
