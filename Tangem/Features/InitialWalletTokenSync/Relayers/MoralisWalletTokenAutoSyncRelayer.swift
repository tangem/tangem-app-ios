//
//  MoralisWalletTokenAutoSyncRelayer.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

struct MoralisWalletTokenAutoSyncRelayer: WalletTokenAutoSyncRelayer {
    private let addressResolver: WalletAddressResolver
    private let tokenBalanceClient: MoralisTokenBalanceClient
    private let coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider

    init(
        addressResolver: WalletAddressResolver,
        tokenBalanceClient: MoralisTokenBalanceClient,
        coinsCatalogProvider: InitialWalletTokenSyncCoinsCatalogProvider
    ) {
        self.addressResolver = addressResolver
        self.tokenBalanceClient = tokenBalanceClient
        self.coinsCatalogProvider = coinsCatalogProvider
    }

    func resolveTokenStream(
        blockchain: Blockchain,
        keyInfos: [KeyInfo]
    ) async throws -> AsyncThrowingStream<TokenItem, Error> {
        let pair = try addressResolver.resolveAddress(for: blockchain, keyInfos: keyInfos)
        let balances = try await tokenBalanceClient.getTokenBalances(
            network: pair.blockchainNetwork.blockchain,
            address: pair.address
        )
        let nonZeroBalances = balances.filter { $0.amount > 0 }

        let contractAddresses = nonZeroBalances
            .filter { !$0.isNativeToken }
            .compactMap { $0.contractAddress }

        let contractAddressToCoin = await coinsCatalogProvider.fetchContractAddressToCoinMap(
            contractAddresses: contractAddresses,
            blockchain: pair.blockchainNetwork.blockchain
        )

        let tokenItems = mapToTokenItems(
            balances: nonZeroBalances,
            blockchainNetwork: pair.blockchainNetwork,
            contractAddressToCoin: contractAddressToCoin
        )

        return AsyncThrowingStream { continuation in
            tokenItems.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}

private extension MoralisWalletTokenAutoSyncRelayer {
    func mapToTokenItems(
        balances: [MoralisTokenBalance],
        blockchainNetwork: BlockchainNetwork,
        contractAddressToCoin: [String: CoinsList.Coin]
    ) -> [TokenItem] {
        balances.compactMap { balance in
            if balance.isNativeToken {
                return .blockchain(blockchainNetwork)
            }

            guard
                let externalContractAddress = balance.contractAddress,
                let contract = contractAddressToCoin[externalContractAddress]
            else {
                return nil
            }

            return makeTokenItem(contract: contract, blockchainNetwork: blockchainNetwork)
        }
    }
}
