//
//  CommonInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct CommonInitialWalletTokenSyncConfigurationProvider: InitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    public init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    public func canHandle(_ blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .veChain, .near, .tezos, .aptos, .algorand, .binance, .stellar,
             .koinos, .sui, .internetComputer, .filecoin, .casper,
             .cosmos, .terraV1, .terraV2, .sei, .ton, .polkadot, .kusama,
             .azero, .joystream, .bittensor, .energyWebX, .xrp, .tron,
             .alephium, .kaspa, .cardano, .chia:
            return true

        // Bitcoin UTXO - Like
        case .bitcoin, .litecoin, .bitcoinCash, .dogecoin, .dash,
             .ravencoin, .ducatus, .clore, .fact0rn, .pepecoin, .radiant:
            return true

        // EVM blockchains supported by this provider.
        case .ethereum, .polygon, .bsc, .arbitrum, .optimism, .avalanche, .fantom, .base, .linea,
             .gnosis, .cronos, .moonbeam, .moonriver, .pulsechain, .chiliz, .monad,
             .ethereumPoW, .disChain, .ethereumClassic, .rsk, .kava, .telos, .octa, .decimal, .xdc,
             .shibarium, .areon, .playa3ullGames, .aurora, .manta, .zkSync, .polygonZkEVM,
             .mantle, .flare, .taraxa, .cyber, .blast, .energyWebEVM, .core, .canxium, .xodex,
             .odysseyChain, .bitrock, .apeChain, .sonic, .vanar, .zkLinkNova, .hyperliquidEVM,
             .quai, .scroll, .arbitrumNova, .plasma:
            return true

        case .solana:
            return false

        // Unsupported obtain provider
        case .hedera:
            return false
        }
    }

    public func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        switch blockchain {
        case .veChain:
            return try await VeChainInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .near:
            return try await NEARInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .tezos:
            return try await TezosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .aptos:
            return try await AptosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .algorand:
            return try await AlgorandInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .binance:
            return try await BinanceInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .stellar:
            return try await StellarInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .koinos:
            return try await KoinosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .sui:
            return try await SuiInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .internetComputer:
            return try await ICPInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .filecoin:
            return try await FilecoinInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .casper:
            return try await CasperInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .cosmos, .terraV1, .terraV2, .sei:
            return try await CosmosInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .ton:
            return try await TONInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .polkadot, .kusama, .azero, .joystream, .bittensor, .energyWebX:
            return try await PolkadotInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .xrp:
            return try await XRPInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .kaspa:
            return try await KaspaInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .bitcoin, .litecoin, .bitcoinCash, .dogecoin, .dash, .ravencoin, .ducatus, .clore, .fact0rn, .pepecoin, .radiant:
            return try await UTXOInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .alephium:
            return try await AlephiumInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .tron:
            return try await TronInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .cardano:
            return try await CardanoInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        case .chia:
            return try await ChiaInitialWalletTokenSyncConfigurationProvider(
                networkServiceFactory: networkServiceFactory
            ).configuration(for: blockchain, address: address)
        default:
            if blockchain.isEvm {
                return try await EVMInitialWalletTokenSyncConfigurationProvider(
                    networkServiceFactory: networkServiceFactory
                ).configuration(for: blockchain, address: address)
            }

            throw BlockchainSdkError.notImplemented
        }
    }
}
