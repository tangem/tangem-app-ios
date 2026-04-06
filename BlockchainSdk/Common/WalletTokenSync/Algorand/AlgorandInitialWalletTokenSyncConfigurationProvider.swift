//
//  AlgorandInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AlgorandInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .algorand = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let algorandNetworkService: AlgorandNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

        do {
            let accountModel = try await algorandNetworkService.getAccount(address: address).async()

            // Same rule as `AlgorandWalletManager.validateMinimalBalanceAccount`.
            if accountModel.coinValue < accountModel.reserveValue {
                return InitialWalletTokenSyncConfiguration(nativeBalance: 0, tokens: [])
            }

            return InitialWalletTokenSyncConfiguration(nativeBalance: accountModel.coinValue, tokens: [])
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return InitialWalletTokenSyncConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }
    }
}
