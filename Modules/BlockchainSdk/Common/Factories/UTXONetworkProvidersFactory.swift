//
//  UTXONetworkProvidersFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

/// Builds `[UTXONetworkProvider]` for bitcoin-like chains. Used by wallet assemblies and `WalletNetworkServiceFactory`.
struct UTXONetworkProvidersFactory {
    private let networkProviderAssembly = NetworkProviderAssembly()

    func makeUTXOProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        switch blockchain {
        case .bitcoin:
            return makeBitcoinProviders(blockchain: blockchain, input: input)
        case .litecoin:
            return makeLitecoinProviders(input: input)
        case .bitcoinCash:
            return makeBitcoinCashProviders(blockchain: blockchain, input: input)
        case .dogecoin:
            return makeDogecoinProviders(input: input)
        case .dash:
            return makeDashProviders(input: input)
        case .ravencoin:
            return makeRavencoinProviders(blockchain: blockchain, input: input)
        case .ducatus:
            return [BitcoreNetworkProvider(configuration: input.tangemProviderConfig)]
        case .clore:
            return makeCloreProviders(blockchain: blockchain, input: input)
        case .pepecoin:
            return makePepecoinProviders(blockchain: blockchain, input: input)
        case .radiant:
            return makeRadiantProviders(blockchain: blockchain, input: input)
        case .fact0rn:
            return makeFact0rnProviders(blockchain: blockchain, input: input)
        default:
            return []
        }
    }

    // MARK: - Bitcoin family (BlockBook / Blockchair / Blockcypher)

    private func makeBitcoinProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes)
                )
            case .getBlock where !blockchain.isTestnet:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .getBlock)
                )
            case .public(let link):
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .public(link))
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .bitcoin(testnet: blockchain.isTestnet),
                        with: input
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .bitcoin(testnet: blockchain.isTestnet),
                        with: input
                    )
                )
            case .mock:
                if let node = APINodeInfoResolver(
                    blockchain: input.blockchain,
                    keysConfig: input.keysConfig
                ).resolve(for: .mock) {
                    let provider = BlockBookUTXOProvider(
                        blockchain: input.blockchain,
                        blockBookConfig: MockBlockBookConfig(urlNode: node.url),
                        networkConfiguration: input.tangemProviderConfig
                    )
                    partialResult.append(provider)
                }
            default:
                break
            }
        }
    }

    private func makeLitecoinProviders(input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes)
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .getBlock)
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .litecoin, with: input)
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(endpoint: .litecoin, with: input)
                )
            default:
                break
            }
        }
    }

    private func makeBitcoinCashProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        let networkParams: UTXONetworkParams = blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams()
        let addressService = BitcoinCashAddressService(networkParams: networkParams)

        return input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input,
                        for: .nowNodes,
                        bitcoinCashAddressService: addressService
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBitcoinCashBlockBookUTXOProvider(
                        with: input,
                        for: .getBlock,
                        bitcoinCashAddressService: addressService
                    )
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .bitcoinCash,
                        with: input
                    )
                )
            default:
                break
            }
        }
    }

    private func makeDogecoinProviders(input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes)
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .getBlock)
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .dogecoin,
                        with: input
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .dogecoin,
                        with: input
                    )
                )
            case .mock:
                if let node = APINodeInfoResolver(
                    blockchain: input.blockchain,
                    keysConfig: input.keysConfig
                ).resolve(for: .mock) {
                    let provider = BlockBookUTXOProvider(
                        blockchain: input.blockchain,
                        blockBookConfig: MockBlockBookConfig(urlNode: node.url),
                        networkConfiguration: input.tangemProviderConfig
                    )
                    partialResult.append(provider)
                }
            default:
                break
            }
        }
    }

    private func makeDashProviders(input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        input.apiInfo.reduce(into: []) { partialResult, providerType in
            switch providerType {
            case .nowNodes:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes)
                )
            case .blockchair:
                partialResult.append(
                    contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(
                        endpoint: .dash,
                        with: input
                    )
                )
            case .blockcypher:
                partialResult.append(
                    networkProviderAssembly.makeBlockcypherNetworkProvider(
                        endpoint: .dash,
                        with: input
                    )
                )
            case .getBlock:
                partialResult.append(
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .getBlock)
                )
            default:
                break
            }
        }
    }

    private func makeRavencoinProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        APIResolver(blockchain: blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, providerType in
                switch providerType {
                case .nowNodes:
                    networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .nowNodes)
                default:
                    RavencoinNetworkProvider(
                        nodeInfo: nodeInfo,
                        provider: .init(configuration: input.tangemProviderConfig)
                    )
                }
            }
    }

    private func makeCloreProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        APIResolver(blockchain: blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                networkProviderAssembly.makeBlockBookUTXOProvider(with: input, for: .clore(nodeInfo.url))
            }
    }

    // MARK: - Electrum

    private func makePepecoinProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })

        return socketManagers.map {
            ElectrumUTXONetworkProvider(
                blockchain: blockchain,
                provider: $0,
                converter: .init(lockingScriptBuilder: .pepecoin(isTestnet: blockchain.isTestnet)),
                settings: PepecoinWalletAssembly.Constants.electrumSettings
            )
        }
    }

    private func makeRadiantProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        let socketManagers: [ElectrumWebSocketProvider] = APIResolver(blockchain: blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                ElectrumWebSocketProvider(url: nodeInfo.url)
            })

        return socketManagers.map {
            ElectrumUTXONetworkProvider(
                blockchain: blockchain,
                provider: $0,
                converter: .init(lockingScriptBuilder: .radiant()),
                settings: RadiantWalletAssembly.Constants.electrumSettings
            )
        }
    }

    private func makeFact0rnProviders(blockchain: Blockchain, input: NetworkProviderAssembly.Input) -> [UTXONetworkProvider] {
        APIResolver(blockchain: blockchain, keysConfig: input.keysConfig)
            .resolveProviders(apiInfos: input.apiInfo, factory: { nodeInfo, _ in
                let electrumWebSocketProvider = ElectrumWebSocketProvider(url: nodeInfo.url)
                return Fact0rnNetworkProvider(provider: electrumWebSocketProvider)
            })
    }
}
