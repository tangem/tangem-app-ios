//
//  TransactionHistoryProviderFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct TransactionHistoryProviderFactory {
    private let keysConfig: BlockchainSdkKeysConfig
    private let apiList: APIList
    private let tangemProviderConfig: TangemProviderConfiguration

    // MARK: - Init

    public init(
        keysConfig: BlockchainSdkKeysConfig,
        tangemProviderConfig: TangemProviderConfiguration,
        apiList: APIList
    ) {
        self.keysConfig = keysConfig
        self.tangemProviderConfig = tangemProviderConfig
        self.apiList = apiList
    }

    // [REDACTED_TODO_COMMENT]
    public func makeProvider(for blockchain: Blockchain, isToken: Bool) -> TransactionHistoryProvider? {
        // Transaction history is only supported on the mainnet
        guard !blockchain.isTestnet else {
            return nil
        }

        let networkAssembly = NetworkProviderAssembly()
        let input = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: keysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfig
        )

        switch blockchain {
        case .bitcoin,
             .litecoin,
             .dogecoin,
             .dash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: makeUTXOBlockBookProviders(
                    for: blockchain,
                    input: input,
                    networkAssembly: networkAssembly
                ),
                mapper: UTXOTransactionHistoryMapper(blockchain: blockchain),
                blockchainName: blockchain.displayName
            )
        case .bitcoinCash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: makeUTXOBlockBookProviders(
                    for: blockchain,
                    input: input,
                    networkAssembly: networkAssembly
                ),
                mapper: UTXOTransactionHistoryMapper(blockchain: blockchain),
                blockchainName: blockchain.displayName
            )
        case .ethereum,
             .ethereumPoW,
             .ethereumClassic,
             .avalanche,
             .arbitrum:
            return EthereumTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes),
                mapper: EthereumTransactionHistoryMapper(blockchain: blockchain)
            )
        case .tron:
            return TronTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes),
                mapper: TronTransactionHistoryMapper(blockchain: blockchain)
            )
        case .apeChain,
             .base,
             .blast,
             .gnosis,
             .hyperliquidEVM,
             .mantle,
             .moonbeam,
             .moonriver,
             .optimism,
             .polygon,
             .polygonZkEVM,
             .sonic,
             .xdc,
             .zkSync,
             .bsc:
            // https://docs.etherscan.io/supported-chains

            guard let chainId = blockchain.chainId else {
                return nil
            }

            return EtherscanTransactionHistoryProvider(
                mapper: EtherscanTransactionHistoryMapper(blockchain: blockchain),
                networkConfiguration: input.tangemProviderConfig,
                targetConfiguration: .etherscan(chainId: chainId, apiKey: keysConfig.etherscanApiKey)
            )
        case .algorand(_, let isTestnet):
            let node: NodeInfo
            if isTestnet {
                node = .init(url: AlgorandIndexProviderTarget.Provider.fullNode(isTestnet: isTestnet).url)
            } else {
                let keyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, keysConfig: keysConfig)
                node = .init(
                    url: AlgorandIndexProviderTarget.Provider.nowNodes.url,
                    keyInfo: keyInfoProvider.apiKeys(for: .nowNodes)
                )
            }

            return AlgorandTransactionHistoryProvider(
                node: node,
                networkConfig: input.tangemProviderConfig,
                mapper: AlgorandTransactionHistoryMapper(blockchain: input.blockchain)
            )
        case .kaspa where !isToken:
            return KaspaTransactionHistoryProvider(
                networkConfiguration: input.tangemProviderConfig,
                mapper: KaspaTransactionHistoryMapper(blockchain: input.blockchain)
            )
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func makeUTXOBlockBookProviders(
        for blockchain: Blockchain,
        input: NetworkProviderAssembly.Input,
        networkAssembly: NetworkProviderAssembly
    ) -> [BlockBookUTXOProvider] {
        var providers: [BlockBookUTXOProvider] = []

        if input.apiInfo.contains(where: { if case .mock = $0 { return true } else { return false } }),
           let mockNode = APINodeInfoResolver(
               blockchain: blockchain,
               keysConfig: keysConfig
           ).resolve(for: .mock) {
            providers.append(
                BlockBookUTXOProvider(
                    blockchain: blockchain,
                    blockBookConfig: MockBlockBookConfig(urlNode: mockNode.url),
                    networkConfiguration: tangemProviderConfig
                )
            )
        }

        providers.append(contentsOf: [
            networkAssembly.makeBlockBookUTXOProvider(with: input, for: .getBlock),
            networkAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes),
        ])

        return providers
    }
}
