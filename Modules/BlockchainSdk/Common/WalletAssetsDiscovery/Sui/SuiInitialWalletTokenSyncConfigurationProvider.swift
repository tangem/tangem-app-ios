//
//  SuiInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct SuiInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard case .sui = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let suiNetworkService: SuiNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let balances = try await suiNetworkService.getBalances(address: address).async()

        let totalNativeBalance = balances
            .filter { $0.coinType == .sui }
            .reduce(into: Decimal.zero) { partialResult, balance in
                partialResult += balance.balance
            }

        let tokenBalancesByType = balances
            .filter { $0.coinType != .sui }
            .reduce(into: [String: Decimal]()) { result, balance in
                result[balance.coinType.string, default: 0] += balance.balance
            }

        let nativeBalance = totalNativeBalance / blockchain.decimalValue
        let tokens = tokenBalancesByType.map { contractAddress, balance in
            WalletAssetsDiscoveryTokenBalance(
                contractAddress: contractAddress,
                balance: balance
            )
        }

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: tokens)
    }
}
