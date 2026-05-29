//
//  ConfigurationWalletAssetsDiscoveryRelayer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ConfigurationWalletAssetsDiscoveryRelayer: WalletAssetsDiscoveryRelayer {
    private let configurationProvider: WalletAssetsDiscoveryBalanceProvider
    private let coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider

    init(
        configurationProvider: WalletAssetsDiscoveryBalanceProvider,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) {
        self.configurationProvider = configurationProvider
        self.coinsCatalogProvider = coinsCatalogProvider
    }

    func resolveTokenStream(
        pair: NetworkAddressPair,
        keyInfos: [KeyInfo]
    ) async throws -> AsyncThrowingStream<TokenItem, Error> {
        let configuration = try await configurationProvider.configuration(
            for: pair.blockchainNetwork.blockchain,
            address: pair.address
        )

        let nonZeroTokenBalances = configuration.tokens.filter { $0.balance > 0 }
        let filteredConfiguration = WalletAssetsDiscoveryBalanceConfiguration(
            nativeBalance: configuration.nativeBalance,
            tokens: nonZeroTokenBalances
        )

        let contractAddresses = nonZeroTokenBalances.map(\.contractAddress)
        let contractAddressToCoin = await coinsCatalogProvider.fetchContractAddressToCoinMap(
            contractAddresses: contractAddresses,
            blockchain: pair.blockchainNetwork.blockchain
        )

        let tokenItems = mapToTokenItems(
            configuration: filteredConfiguration,
            blockchainNetwork: pair.blockchainNetwork,
            contractAddressToCoin: contractAddressToCoin
        )

        return AsyncThrowingStream { continuation in
            tokenItems.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}

private extension ConfigurationWalletAssetsDiscoveryRelayer {
    func mapToTokenItems(
        configuration: WalletAssetsDiscoveryBalanceConfiguration,
        blockchainNetwork: BlockchainNetwork,
        contractAddressToCoin: [String: CoinsList.Coin]
    ) -> [TokenItem] {
        var tokenItems: [TokenItem] = []

        if configuration.hasNativeBalance {
            tokenItems.append(.blockchain(blockchainNetwork))
        }

        for tokenBalance in configuration.tokens {
            guard let coin = contractAddressToCoin[tokenBalance.contractAddress] else {
                continue
            }

            if let token = makeTokenItem(contract: coin, blockchainNetwork: blockchainNetwork) {
                tokenItems.append(token)
            }
        }

        return tokenItems
    }
}
