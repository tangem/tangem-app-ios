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
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .sui = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let suiNetworkService: SuiNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let balanceResult = try await suiNetworkService.getBalance(address: address, coinType: .sui, cursor: nil).async()
        let coins = try balanceResult.get()

        let objects = coins.compactMap {
            try? SuiCoinObject.from($0)
        }

        let totalNativeBalance = objects
            .filter { $0.coinType == .sui }
            .reduce(into: Decimal.zero) { partialResult, coin in
                partialResult += coin.balance
            }

        let tokenBalancesByType = objects
            .filter { $0.coinType != .sui }
            .reduce(into: [String: Decimal]()) { result, coin in
                result[coin.coinType.string, default: 0] += coin.balance
            }

        let nativeBalance = totalNativeBalance / blockchain.decimalValue
        let tokens = tokenBalancesByType.map { contractAddress, balance in
            InitialWalletTokenSyncTokenBalance(
                contractAddress: contractAddress,
                balance: balance
            )
        }

        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: tokens)
    }
}
