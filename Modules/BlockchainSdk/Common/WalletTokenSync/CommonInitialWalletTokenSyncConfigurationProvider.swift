//
//  CommonInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct CommonInitialWalletTokenSyncConfigurationProvider: InitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: () -> WalletNetworkServiceFactory
    private let isSolanaScaledUIEnabled: Bool

    public init(
        networkServiceFactory: @escaping @autoclosure () -> WalletNetworkServiceFactory,
        isSolanaScaledUIEnabled: Bool = true
    ) {
        self.networkServiceFactory = networkServiceFactory
        self.isSolanaScaledUIEnabled = isSolanaScaledUIEnabled
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    public func canHandle(_ blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .veChain, .near, .tezos, .aptos, .algorand, .binance, .stellar,
             .koinos, .sui, .internetComputer, .filecoin, .casper,
             .cosmos, .terraV1, .terraV2, .sei, .ton, .polkadot, .kusama,
             .azero, .joystream, .bittensor, .energyWebX, .xrp, .tron,
             .alephium, .kaspa, .cardano, .chia, .solana:
            return true

        // Bitcoin UTXO - Like
        case .bitcoin, .litecoin, .bitcoinCash, .dogecoin, .dash,
             .ravencoin, .ducatus, .clore, .fact0rn, .pepecoin, .radiant:
            return true

        // EVM blockchains from MoralisSupportedBlockchains.
        case .ethereum, .polygon, .bsc, .arbitrum, .optimism, .avalanche, .fantom, .base, .linea,
             .gnosis, .cronos, .moonbeam, .moonriver, .pulsechain, .chiliz, .monad, .seiEvm:
            return true

        // Other EVM blockchains supported by this provider.
        case .ethereumPoW, .disChain, .ethereumClassic, .rsk, .kava, .telos, .octa, .decimal, .xdc,
             .shibarium, .areon, .playa3ullGames, .aurora, .manta, .zkSync, .polygonZkEVM,
             .mantle, .flare, .taraxa, .cyber, .blast, .energyWebEVM, .core, .canxium, .xodex,
             .odysseyChain, .bitrock, .apeChain, .sonic, .vanar, .zkLinkNova, .hyperliquidEVM,
             .quai, .scroll, .arbitrumNova, .plasma:
            return true

        // Unsupported obtain provider
        case .hedera:
            return false
        }
    }

    public func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        let factory = networkServiceFactory()

        switch blockchain {
        case .veChain:
            return try await VeChainInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .near:
            return try await NEARInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .tezos:
            return try await TezosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .aptos:
            return try await AptosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .algorand:
            return try await AlgorandInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .binance:
            return try await BinanceInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .stellar:
            return try await StellarInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .koinos:
            return try await KoinosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .sui:
            return try await SuiInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .internetComputer:
            return try await ICPInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .filecoin:
            return try await FilecoinInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .casper:
            return try await CasperInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .cosmos, .terraV1, .terraV2, .sei:
            return try await CosmosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .ton:
            return try await TONInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .polkadot, .kusama, .azero, .joystream, .bittensor, .energyWebX:
            return try await PolkadotInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .xrp:
            return try await XRPInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .kaspa:
            return try await KaspaInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .bitcoin, .litecoin, .bitcoinCash, .dogecoin, .dash, .ravencoin, .ducatus, .clore, .fact0rn, .pepecoin, .radiant:
            return try await UTXOInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .alephium:
            return try await AlephiumInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .tron:
            return try await TronInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .cardano:
            return try await CardanoInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .chia:
            return try await ChiaInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory
            ).configuration(for: blockchain, address: address)
        case .solana:
            return try await SolanaInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: factory,
                isSolanaScaledUIEnabled: isSolanaScaledUIEnabled
            ).configuration(for: blockchain, address: address)
        default:
            if blockchain.isEvm {
                return try await EVMInitialWalletTokenSyncConfigurationProvider(
                    networkServiceFactory: factory
                ).configuration(for: blockchain, address: address)
            }

            throw BlockchainSdkError.notImplemented
        }
    }
}
