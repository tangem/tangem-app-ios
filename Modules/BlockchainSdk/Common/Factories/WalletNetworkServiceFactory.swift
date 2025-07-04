//
//  WalletNetworkServiceFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct WalletNetworkServiceFactory {
    // MARK: - Private Properties

    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let tangemProviderConfig: TangemProviderConfiguration
    private let apiList: APIList

    // MARK: - Init

    init(
        blockchainSdkKeysConfig: BlockchainSdkKeysConfig,
        tangemProviderConfig: TangemProviderConfiguration,
        apiList: APIList
    ) {
        self.blockchainSdkKeysConfig = blockchainSdkKeysConfig
        self.tangemProviderConfig = tangemProviderConfig
        self.apiList = apiList
    }
}

// MARK: - Generic Implementation

extension WalletNetworkServiceFactory {
    func makeServiceWithType<T: MultiNetworkProvider>(for blockchain: Blockchain) throws -> T {
        guard let service = try makeService(for: blockchain) as? T else {
            throw Error.unsupportedType
        }

        return service
    }

    func makeService(for blockchain: Blockchain) throws -> any MultiNetworkProvider {
        switch blockchain {
        case .bitcoin:
            throw Error.notImplemeneted
        case .litecoin:
            throw Error.notImplemeneted
        case .stellar:
            throw Error.notImplemeneted
        case .ethereum,
             .ethereumClassic,
             .ethereumPoW,
             .disChain,
             .bsc,
             .polygon,
             .avalanche,
             .fantom,
             .arbitrum,
             .gnosis,
             .optimism,
             .kava,
             .cronos,
             .telos,
             .octa,
             .shibarium,
             .areon,
             .playa3ullGames,
             .pulsechain,
             .aurora,
             .manta,
             .zkSync,
             .moonbeam,
             .polygonZkEVM,
             .moonriver,
             .mantle,
             .flare,
             .taraxa,
             .base,
             .cyber,
             .blast,
             .energyWebEVM,
             .core,
             .canxium,
             .chiliz,
             .xodex,
             .odysseyChain,
             .bitrock,
             .apeChain,
             .sonic,
             .vanar,
             .zkLinkNova:
            return makeEthereumNetworkService(for: blockchain)
        case .rsk:
            throw Error.notImplemeneted
        case .bitcoinCash:
            throw Error.notImplemeneted
        case .binance:
            throw Error.notImplemeneted
        case .cardano:
            throw Error.notImplemeneted
        case .xrp:
            throw Error.notImplemeneted
        case .tezos:
            throw Error.notImplemeneted
        case .dogecoin:
            throw Error.notImplemeneted
        case .solana:
            throw Error.notImplemeneted
        case .polkadot:
            throw Error.notImplemeneted
        case .kusama:
            throw Error.notImplemeneted
        case .azero:
            throw Error.notImplemeneted
        case .tron:
            throw Error.notImplemeneted
        case .dash:
            throw Error.notImplemeneted
        case .kaspa:
            throw Error.notImplemeneted
        case .ravencoin:
            throw Error.notImplemeneted
        case .cosmos,
             .terraV1,
             .terraV2,
             .veChain,
             .internetComputer,
             .algorand,
             .sei,
             .ton:
            throw Error.notImplemeneted
        case .aptos:
            throw Error.notImplemeneted
        case .ducatus:
            throw Error.notImplemeneted
        case .chia:
            throw Error.notImplemeneted
        case .near:
            return makeNEARNetworkService(for: blockchain)
        case .decimal:
            throw Error.notImplemeneted
        case .xdc:
            throw Error.notImplemeneted
        case .hedera:
            throw Error.notImplemeneted
        case .radiant:
            throw Error.notImplemeneted
        case .joystream:
            throw Error.notImplemeneted
        case .bittensor:
            throw Error.notImplemeneted
        case .koinos:
            throw Error.notImplemeneted
        case .sui:
            throw Error.notImplemeneted
        case .filecoin:
            throw Error.notImplemeneted
        case .energyWebX:
            throw Error.notImplemeneted
        case .casper:
            throw Error.notImplemeneted
        case .clore:
            throw Error.notImplemeneted
        case .fact0rn:
            throw Error.notImplemeneted
        case .alephium:
            throw Error.notImplemeneted
        case .pepecoin:
            throw Error.notImplemeneted
        }
    }
}

// MARK: - Chains Implementation

private extension WalletNetworkServiceFactory {
    /// EVM
    func makeEthereumNetworkService(for blockchain: Blockchain) -> EthereumNetworkService {
        let networkAssembly = NetworkProviderAssembly()

        let networkService = EthereumNetworkService(
            decimals: blockchain.decimalCount,
            providers: networkAssembly.makeEthereumJsonRpcProviders(with: NetworkProviderAssembly.Input(
                blockchain: blockchain,
                keysConfig: blockchainSdkKeysConfig,
                apiInfo: apiList[blockchain.networkId] ?? [],
                tangemProviderConfig: tangemProviderConfig
            )),
            abiEncoder: WalletCoreABIEncoder()
        )

        return networkService
    }

    /// NEAR
    func makeNEARNetworkService(for blockchain: Blockchain) -> NEARNetworkService {
        let providers: [NEARNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                return NEARNetworkProvider(baseURL: nodeInfo.url, configuration: tangemProviderConfig)
            }

        let networkService = NEARNetworkService(blockchain: blockchain, providers: providers)

        return networkService
    }
}

// MARK: - Errors

extension WalletNetworkServiceFactory {
    enum Error: Swift.Error {
        // [REDACTED_TODO_COMMENT]
        case notImplemeneted
        case unsupportedType
    }
}
