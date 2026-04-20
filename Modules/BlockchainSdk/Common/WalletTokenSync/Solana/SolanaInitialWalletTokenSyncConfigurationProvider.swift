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
    private let isSolanaScaledUIEnabled: Bool

    init(
        networkServiceFactory: WalletNetworkServiceFactory,
        isSolanaScaledUIEnabled: Bool
    ) {
        self.networkServiceFactory = networkServiceFactory
        self.isSolanaScaledUIEnabled = isSolanaScaledUIEnabled
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .solana = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let solanaNetworkService: SolanaNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        solanaNetworkService.isSolanaScaledUIEnabled = isSolanaScaledUIEnabled
        let balances = try await solanaNetworkService.getInitialWalletInfo(accountId: address).async()
        let tokenBalances = balances.tokenBalancesByMint.map { contractAddress, info in
            InitialWalletTokenSyncTokenBalance(contractAddress: contractAddress, balance: info.balance)
        }

        return InitialWalletTokenSyncConfiguration(
            nativeBalance: balances.mainBalance,
            tokens: tokenBalances
        )
    }
}
