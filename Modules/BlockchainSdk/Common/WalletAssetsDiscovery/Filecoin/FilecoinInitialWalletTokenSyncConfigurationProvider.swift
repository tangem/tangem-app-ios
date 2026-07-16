//
//  FilecoinInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FilecoinInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .filecoin = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let filecoinNetworkService: FilecoinNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

        do {
            let accountInfo = try await filecoinNetworkService.getAccountInfo(address: address).async()
            let nativeBalance = accountInfo.balance / blockchain.decimalValue
            return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
        } catch {
            if case BlockchainSdkError.noAccount = error {
                return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: 0, tokens: [])
            }

            throw error
        }
    }
}
