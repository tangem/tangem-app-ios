//
//  PolkadotInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemFoundation

/// Initial wallet token sync for Substrate networks backed by `PolkadotNetworkService` (Polkadot, Kusama, Aleph Zero, Joystream, Bittensor, Energy Web X).
struct PolkadotInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration {
        guard PolkadotNetwork(blockchain: blockchain) != nil else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService: PolkadotNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let rawBalance = try await networkService.getInfo(for: address).async()
        let decimals = blockchain.decimalCount
        let nativeBalance: Decimal
        if
            let formatted = EthereumUtils.formatToPrecision(
                rawBalance,
                numberDecimals: decimals,
                formattingDecimals: decimals,
                decimalSeparator: ".",
                fallbackToScientific: false
            ),
            let value = Decimal(stringValue: formatted) {
            nativeBalance = value
        } else {
            nativeBalance = 0
        }

        return WalletAssetsDiscoveryBalanceConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
