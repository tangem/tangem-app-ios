//
//  NetworkProviderAssembly.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct NetworkProviderAssembly {
    // [REDACTED_TODO_COMMENT]
    func makeBlockBookUTXOProvider(
        with input: Input,
        for type: BlockBookProviderType
    ) -> BlockBookUTXOProvider {
        switch type {
        case .nowNodes:
            return BlockBookUTXOProvider(
                blockchain: input.blockchain,
                blockBookConfig: NowNodesBlockBookConfig(
                    apiKeyHeaderName: Constants.nowNodesApiKeyHeaderName,
                    apiKeyHeaderValue: input.keysConfig.nowNodesApiKey
                ),
                networkConfiguration: input.tangemProviderConfig
            )
        case .getBlock:
            return BlockBookUTXOProvider(
                blockchain: input.blockchain,
                blockBookConfig: GetBlockBlockBookConfig(input.keysConfig.getBlockCredentials),
                networkConfiguration: input.tangemProviderConfig
            )
        case .clore(let url):
            return CloreBlockBookUTXOProvider(
                blockchain: input.blockchain,
                blockBookConfig: CloreBlockBookConfig(urlNode: url),
                networkConfiguration: input.tangemProviderConfig
            )
        }
    }

    // [REDACTED_TODO_COMMENT]
    func makeBitcoinCashBlockBookUTXOProvider(
        with input: Input,
        for type: BlockBookProviderType,
        bitcoinCashAddressService: BitcoinCashAddressService
    ) -> UTXONetworkProvider {
        BitcoinCashBlockBookUTXOProvider(
            blockBookUTXOProvider: makeBlockBookUTXOProvider(with: input, for: type),
            bitcoinCashAddressService: bitcoinCashAddressService
        )
    }

    // [REDACTED_TODO_COMMENT]
    func makeBlockcypherNetworkProvider(endpoint: BlockcypherEndpoint, with input: Input) -> BlockcypherNetworkProvider {
        BlockcypherNetworkProvider(
            endpoint: endpoint,
            tokens: input.keysConfig.blockcypherTokens,
            blockchain: input.blockchain,
            configuration: input.tangemProviderConfig
        )
    }

    // [REDACTED_TODO_COMMENT]
    func makeBlockchairNetworkProviders(endpoint: BlockchairEndpoint, with input: Input) -> [UTXONetworkProvider] {
        let apiKeys: [String?] = [nil] + input.keysConfig.blockchairApiKeys

        return apiKeys.map {
            BlockchairNetworkProvider(endpoint: endpoint, apiKey: $0, blockchain: input.blockchain, configuration: input.tangemProviderConfig)
        }
    }

    func makeEthereumJsonRpcProviders(with input: Input) -> [EthereumJsonRpcProvider] {
        return APIResolver(blockchain: input.blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, networkProviderType in
                EthereumJsonRpcProvider(
                    node: nodeInfo,
                    configuration: input.tangemProviderConfig,
                    networkPrefix: .init(blockchain: input.blockchain),
                    networkProviderType: networkProviderType,
                )
            }
    }
}

extension NetworkProviderAssembly {
    struct Input {
        let blockchain: Blockchain
        let keysConfig: BlockchainSdkKeysConfig
        let apiInfo: [NetworkProviderType]
        let tangemProviderConfig: TangemProviderConfiguration
    }
}

private extension EthereumTarget.RPCNetworkPrefix {
    init(blockchain: Blockchain) {
        switch blockchain {
        case .quai:
            self = .quai
        default:
            self = .ethereum
        }
    }
}
