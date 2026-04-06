//
//  TronInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TronInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .tron = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let tronNetworkService: TronNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let accountInfo = try await tronNetworkService.getAccountInfoByAddress(address).async()

        let tokenBalances = accountInfo.tokenBalances
            .filter { $0.value > 0 }
            .map { InitialWalletTokenSyncTokenBalance(contractAddress: $0.key, balance: $0.value) }

        return InitialWalletTokenSyncConfiguration(nativeBalance: accountInfo.balance, tokens: tokenBalances)
    }
}
