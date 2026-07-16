//
//  CasperInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CasperInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .casper = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let casperNetworkService: CasperNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let balanceInfo = try await casperNetworkService.getBalance(address: address).async()

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: balanceInfo.value, tokens: [])
    }
}
