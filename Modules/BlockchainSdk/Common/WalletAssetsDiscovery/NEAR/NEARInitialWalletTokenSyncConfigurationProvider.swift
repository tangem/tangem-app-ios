//
//  NEARInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct NEARInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .near = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let nearNetworkService: NEARNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let accountInfo = try await nearNetworkService.getInfo(accountId: address).async()

        switch accountInfo {
        case .initialized(let account):
            return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: account.amount.value, tokens: [])
        case .notInitialized:
            return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: 0, tokens: [])
        }
    }
}
