//
//  AptosInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AptosInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .aptos = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let aptosNetworkService: AptosNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

        do {
            let accountInfo = try await aptosNetworkService.getAccount(address: address).async()
            let nativeBalance = accountInfo.balance / blockchain.decimalValue
            return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return InitialWalletTokenSyncConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }
    }
}
