//
//  SolanaInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SolanaInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(
        networkServiceFactory: WalletNetworkServiceFactory
    ) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .solana = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let solanaNetworkService: SolanaNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let balances = try await solanaNetworkService.getInitialWalletInfo(accountId: address).async()
        let tokenBalances = balances.tokenBalancesByMint.map { contractAddress, info in
            WalletAssetsDiscoveryTokenBalance(contractAddress: contractAddress, balance: info.balance)
        }

        return WalletAssetsDiscoveryBalanceConfiguration(
            nativeBalance: balances.mainBalance,
            tokens: tokenBalances
        )
    }
}
