//
//  WalletNetworkServiceFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils
import SolanaSwift
import IcpKit

public struct WalletNetworkServiceFactory {
    // MARK: - Private Properties

    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let tangemProviderConfig: TangemProviderConfiguration
    private let apiList: APIList

    // MARK: - Init

    public init(
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
        case .bitcoin,
             .litecoin,
             .bitcoinCash,
             .dogecoin,
             .dash,
             .ravencoin,
             .ducatus,
             .radiant,
             .clore,
             .fact0rn,
             .pepecoin:
            return try makeUTXONetworkService(for: blockchain)
        case .kaspa:
            return try makeKaspaNetworkService(for: blockchain)
        case .stellar:
            return makeStellarNetworkService(for: blockchain)
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
             .zkLinkNova,
             .hyperliquidEVM,
             .quai,
             .scroll,
             .linea,
             .monad,
             .arbitrumNova,
             .plasma,
             .adi,
             .seiEvm,
             .decimal,
             .xdc,
             .rsk:
            return makeEthereumNetworkService(for: blockchain)
        case .binance:
            throw Error.notImplemeneted
        case .cardano:
            return makeCardanoNetworkService(for: blockchain)
        case .xrp:
            return makeXRPNetworkService(for: blockchain)
        case .tezos:
            return makeTezosNetworkService(for: blockchain)
        case .solana:
            return try makeSolanaNetworkService(for: blockchain)
        case .polkadot:
            return try makeSubstrateNetworkService(for: blockchain)
        case .kusama:
            return try makeSubstrateNetworkService(for: blockchain)
        case .azero:
            return try makeSubstrateNetworkService(for: blockchain)
        case .tron:
            return makeTronNetworkService(for: blockchain)
        case .algorand:
            return makeAlgorandNetworkService(for: blockchain)
        case .cosmos,
             .terraV1,
             .terraV2,
             .sei:
            return try makeCosmosNetworkService(for: blockchain)
        case .ton:
            return makeTONNetworkService(for: blockchain)
        case .internetComputer:
            return makeICPNetworkService(for: blockchain)
        case .veChain:
            return makeVeChainNetworkService(for: blockchain)
        case .aptos:
            return makeAptosNetworkService(for: blockchain)
        case .chia:
            return makeChiaNetworkService(for: blockchain)
        case .near:
            return makeNEARNetworkService(for: blockchain)
        case .hedera:
            return makeHederaNetworkService(for: blockchain)
        case .joystream:
            return try makeSubstrateNetworkService(for: blockchain)
        case .bittensor:
            return try makeSubstrateNetworkService(for: blockchain)
        case .energyWebX:
            return try makeSubstrateNetworkService(for: blockchain)
        case .koinos:
            return makeKoinosNetworkService(for: blockchain)
        case .sui:
            return makeSuiNetworkService(for: blockchain)
        case .filecoin:
            return makeFilecoinNetworkService(for: blockchain)
        case .casper:
            return makeCasperNetworkService(for: blockchain)
        case .alephium:
            return makeAlephiumNetworkService(for: blockchain)
        }
    }

    /// EVM with specific provider type
    func makeEthereumNetworkServiceIfAvailable(
        for blockchain: Blockchain,
        with providerType: NetworkProviderType
    ) -> EthereumNetworkService? {
        let networkAssembly = NetworkProviderAssembly()

        let allProviders = networkAssembly.makeEthereumJsonRpcProviders(with: NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfig
        ))

        let filteredProviders = allProviders.filter { $0.networkProviderType == providerType }

        guard !filteredProviders.isEmpty else {
            return nil
        }

        return EthereumNetworkService(
            decimals: blockchain.decimalCount,
            providers: filteredProviders,
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: blockchain.displayName
        )
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
            abiEncoder: WalletCoreABIEncoder(),
            blockchainName: blockchain.displayName
        )

        return networkService
    }

    /// Hedera
    func makeHederaNetworkService(for blockchain: Blockchain) -> HederaNetworkService {
        let restProviders = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                HederaRESTNetworkProvider(targetConfiguration: nodeInfo, providerConfiguration: tangemProviderConfig)
            }

        let consensusProvider = HederaConsensusNetworkProvider(
            isTestnet: blockchain.isTestnet,
            timeout: tangemProviderConfig.urlSessionConfiguration.timeoutIntervalForRequest
        )

        let networkService = HederaNetworkService(
            consensusProvider: consensusProvider,
            restProviders: restProviders
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

    /// XRP
    func makeXRPNetworkService(for blockchain: Blockchain) -> XRPNetworkService {
        let providers: [XRPNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                XRPNetworkProvider(node: nodeInfo, configuration: tangemProviderConfig)
            }

        return XRPNetworkService(providers: providers)
    }

    /// Stellar
    func makeStellarNetworkService(for blockchain: Blockchain) -> StellarNetworkService {
        let providers: [StellarNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                StellarNetworkProvider(
                    isTestnet: blockchain.isTestnet,
                    horizonUrl: nodeInfo.link
                )
            }

        return StellarNetworkService(providers: providers)
    }

    /// Tezos
    func makeTezosNetworkService(for blockchain: Blockchain) -> TezosNetworkService {
        let providers: [TezosJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                TezosJsonRpcProvider(nodeInfo: nodeInfo, configuration: tangemProviderConfig)
            }

        return TezosNetworkService(providers: providers)
    }

    /// Solana
    func makeSolanaNetworkService(for blockchain: Blockchain) throws -> SolanaNetworkService {
        let endpoints: [RPCEndpoint] = if blockchain.isTestnet {
            [.devnetSolana, .devnetGenesysGo]
        } else {
            APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
                .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, networkProviderType in
                    guard var components = URLComponents(url: nodeInfo.url, resolvingAgainstBaseURL: false) else {
                        return nil
                    }

                    components.scheme = SolanaConstants.webSocketScheme
                    guard let urlWebSocket = components.url else {
                        return nil
                    }

                    let headerNameValue: (name: String?, value: String?)? = if case .nowNodes = networkProviderType {
                        (nodeInfo.headers?.headerName, nodeInfo.headers?.headerValue)
                    } else {
                        nil
                    }

                    var sendSkipPreflight = false

                    if case .blink = networkProviderType {
                        sendSkipPreflight = true
                    }

                    return RPCEndpoint(
                        url: nodeInfo.url,
                        urlWebSocket: urlWebSocket,
                        network: .mainnetBeta,
                        apiKeyHeaderName: headerNameValue?.name,
                        apiKeyHeaderValue: headerNameValue?.value,
                        sendSkipPreflight: sendSkipPreflight
                    )
                }
        }

        guard !endpoints.isEmpty else {
            throw BlockchainSdkError.noAPIInfo
        }

        let apiLogger = SolanaApiLoggerUtil()
        let session = TangemTrustEvaluatorUtil.makeSession(configuration: .ephemeralConfiguration)
        let networkRouter = NetworkingRouter(endpoints: endpoints, session: session, apiLogger: apiLogger)
        let accountStorage = SolanaDummyAccountStorage()
        let solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)

        return SolanaNetworkService(
            providers: endpoints,
            solanaSdk: solanaSdk,
            blockchain: blockchain,
            providerConfiguration: tangemProviderConfig
        )
    }

    /// Algorand
    func makeAlgorandNetworkService(for blockchain: Blockchain) -> AlgorandNetworkService {
        let providers: [AlgorandNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                AlgorandNetworkProvider(node: nodeInfo, networkConfig: tangemProviderConfig)
            }

        return AlgorandNetworkService(blockchain: blockchain, providers: providers)
    }

    /// Aptos
    func makeAptosNetworkService(for blockchain: Blockchain) -> AptosNetworkService {
        let providers: [AptosNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                AptosNetworkProvider(node: nodeInfo, networkConfig: tangemProviderConfig)
            }

        return AptosNetworkService(providers: providers)
    }

    /// VeChain
    func makeVeChainNetworkService(for blockchain: Blockchain) -> VeChainNetworkService {
        let providers: [VeChainNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                VeChainNetworkProvider(nodeInfo: nodeInfo, configuration: tangemProviderConfig)
            }

        return VeChainNetworkService(blockchain: blockchain, providers: providers)
    }

    /// Tron
    func makeTronNetworkService(for blockchain: Blockchain) -> TronNetworkService {
        let providers: [TronJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                TronJsonRpcProvider(node: nodeInfo, configuration: tangemProviderConfig)
            }

        return TronNetworkService(isTestnet: blockchain.isTestnet, providers: providers)
    }

    /// Koinos
    func makeKoinosNetworkService(for blockchain: Blockchain) -> KoinosNetworkService {
        let koinosNetworkParams = KoinosNetworkParams(isTestnet: blockchain.isTestnet)
        let providers: [KoinosNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                KoinosNetworkProvider(
                    node: nodeInfo,
                    koinosNetworkParams: koinosNetworkParams,
                    configuration: tangemProviderConfig
                )
            }

        return KoinosNetworkService(providers: providers)
    }

    /// Sui
    func makeSuiNetworkService(for blockchain: Blockchain) -> SuiNetworkService {
        let providers: [SuiNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                SuiNetworkProvider(
                    node: nodeInfo,
                    networkConfiguration: tangemProviderConfig
                )
            }

        return SuiNetworkService(providers: providers)
    }

    /// ICP
    func makeICPNetworkService(for blockchain: Blockchain) -> ICPNetworkService {
        let providers: [ICPNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                ICPNetworkProvider(
                    node: nodeInfo,
                    networkConfig: tangemProviderConfig,
                    responseParser: ICPResponseParser()
                )
            }

        return ICPNetworkService(providers: providers, blockchain: blockchain)
    }

    /// Filecoin
    func makeFilecoinNetworkService(for blockchain: Blockchain) -> FilecoinNetworkService {
        let providers: [FilecoinNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                FilecoinNetworkProvider(
                    node: nodeInfo,
                    configuration: tangemProviderConfig
                )
            }

        return FilecoinNetworkService(providers: providers)
    }

    /// Alephium
    func makeAlephiumNetworkService(for blockchain: Blockchain) -> AlephiumNetworkService {
        let providers: [AlephiumNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                AlephiumNetworkProvider(
                    node: nodeInfo,
                    networkConfig: tangemProviderConfig
                )
            }

        return AlephiumNetworkService(providers: providers)
    }

    /// Casper
    func makeCasperNetworkService(for blockchain: Blockchain) -> CasperNetworkService {
        let providers: [CasperNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                CasperNetworkProvider(
                    node: nodeInfo,
                    configuration: tangemProviderConfig
                )
            }

        return CasperNetworkService(
            providers: providers,
            blockchainDecimalValue: blockchain.decimalValue
        )
    }

    /// Cosmos Hub, Terra, Sei (Cosmos SDK REST)
    func makeCosmosNetworkService(for blockchain: Blockchain) throws -> CosmosNetworkService {
        let cosmosChain: CosmosChain
        switch blockchain {
        case .cosmos(let testnet):
            cosmosChain = .cosmos(testnet: testnet)
        case .terraV1:
            cosmosChain = .terraV1
        case .terraV2:
            cosmosChain = .terraV2
        case .sei(let isTestnet):
            cosmosChain = .sei(testnet: isTestnet)
        default:
            throw BlockchainSdkError.notImplemented
        }

        let providers: [CosmosRestProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                CosmosRestProvider(nodeInfo: nodeInfo, configuration: tangemProviderConfig)
            }

        return CosmosNetworkService(cosmosChain: cosmosChain, providers: providers)
    }

    /// The Open Network (TON)
    func makeTONNetworkService(for blockchain: Blockchain) -> TONNetworkService {
        let providers: [TONProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                TONProvider(node: nodeInfo, networkConfig: tangemProviderConfig)
            }

        return TONNetworkService(providers: providers, blockchain: blockchain)
    }

    /// Substrate chains (Polkadot, Kusama, Aleph Zero, Joystream, Bittensor, Energy Web X)
    func makeSubstrateNetworkService(for blockchain: Blockchain) throws -> PolkadotNetworkService {
        guard let network = PolkadotNetwork(blockchain: blockchain) else {
            throw BlockchainSdkError.notImplemented
        }

        var providers: [PolkadotJsonRpcProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                PolkadotJsonRpcProvider(node: nodeInfo, configuration: tangemProviderConfig)
            }

        let dwellirResolver = DwellirAPIResolver(keysConfig: blockchainSdkKeysConfig)
        if let dwellirNodeInfo = dwellirResolver.resolve(for: blockchain) {
            providers.append(PolkadotJsonRpcProvider(node: dwellirNodeInfo, configuration: tangemProviderConfig))
        }

        return PolkadotNetworkService(providers: providers, network: network)
    }

    /// Cardano
    func makeCardanoNetworkService(for blockchain: Blockchain) -> CardanoNetworkService {
        let cardanoResponseMapper = CardanoResponseMapper()
        let linkResolver = APINodeInfoResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)

        let providers: [AnyCardanoNetworkProvider] = (apiList[blockchain.networkId] ?? []).compactMap { providerType in
            guard let nodeInfo = linkResolver.resolve(for: providerType) else {
                return nil
            }

            switch providerType {
            case .getBlock, .tangemRosetta, .nowNodes, .mock:
                return RosettaNetworkProvider(
                    url: nodeInfo.url,
                    configuration: tangemProviderConfig,
                    cardanoResponseMapper: cardanoResponseMapper
                ).eraseToAnyCardanoNetworkProvider()
            case .adalite:
                return AdaliteNetworkProvider(
                    url: nodeInfo.url,
                    configuration: tangemProviderConfig,
                    cardanoResponseMapper: cardanoResponseMapper
                ).eraseToAnyCardanoNetworkProvider()
            default:
                return nil
            }
        }

        return CardanoNetworkService(providers: providers)
    }

    /// Chia
    func makeChiaNetworkService(for blockchain: Blockchain) -> ChiaNetworkService {
        let providers: [ChiaNetworkProvider] = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: apiList[blockchain.networkId] ?? []) { nodeInfo, _ in
                ChiaNetworkProvider(node: nodeInfo, networkConfig: tangemProviderConfig)
            }

        return ChiaNetworkService(providers: providers, blockchain: blockchain)
    }

    func makeUTXONetworkService(for blockchain: Blockchain) throws -> any MultiNetworkProvider {
        let input = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfig
        )

        let utxoFactory = UTXONetworkProvidersFactory()

        switch blockchain {
        case .bitcoin:
            let providers = utxoFactory.makeUTXOProviders(blockchain: blockchain, input: input)
            guard !providers.isEmpty else {
                throw BlockchainSdkError.noAPIInfo
            }

            return BitcoinNetworkService(
                providers: providers,
                blockchainName: blockchain.displayName
            )
        case .litecoin:
            let providers = utxoFactory.makeUTXOProviders(blockchain: blockchain, input: input)
            guard !providers.isEmpty else {
                throw BlockchainSdkError.noAPIInfo
            }

            return LitecoinNetworkService(
                providers: providers,
                blockchainName: blockchain.displayName
            )
        case .bitcoinCash:
            let providers = utxoFactory.makeUTXOProviders(blockchain: blockchain, input: input)
            guard !providers.isEmpty else {
                throw BlockchainSdkError.noAPIInfo
            }

            return BitcoinCashNetworkService(
                providers: providers,
                blockchainName: blockchain.displayName
            )
        case .dogecoin,
             .dash,
             .ravencoin,
             .ducatus,
             .radiant,
             .clore,
             .fact0rn,
             .pepecoin:
            let providers = utxoFactory.makeUTXOProviders(blockchain: blockchain, input: input)
            guard !providers.isEmpty else {
                throw BlockchainSdkError.noAPIInfo
            }

            return MultiUTXONetworkProvider(
                providers: providers,
                blockchainName: blockchain.displayName
            )
        default:
            throw BlockchainSdkError.notImplemented
        }
    }

    func makeKaspaNetworkService(for blockchain: Blockchain) throws -> KaspaNetworkService {
        let input = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfig
        )

        let providers = APIResolver(blockchain: blockchain, keysConfig: blockchainSdkKeysConfig)
            .resolveProviders(apiInfos: input.apiInfo) { nodeInfo, _ in
                KaspaNetworkProvider(
                    url: nodeInfo.url,
                    isTestnet: blockchain.isTestnet,
                    networkConfiguration: tangemProviderConfig
                )
            }

        guard !providers.isEmpty else {
            throw BlockchainSdkError.noAPIInfo
        }

        return KaspaNetworkService(providers: providers)
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

// MARK: - Constants

extension WalletNetworkServiceFactory {
    enum SolanaConstants {
        static let webSocketScheme = "wss"
    }
}
