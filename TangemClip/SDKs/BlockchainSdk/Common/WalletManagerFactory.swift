//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    /// Base wallet manager initializer
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - seedKey: Public key  of the wallet
    ///   - derivedKey: Derived ExtendedPublicKey by the card
    ///   - derivationPath: DerivationPath for derivedKey
    /// - Returns: WalletManager?
    public func makeWalletManager(cardId: String,
                                  blockchain: Blockchain,
                                  seedKey: Data,
                                  derivedKey: ExtendedPublicKey) throws -> WalletManager {
        return try makeWalletManager(from: blockchain,
                                     publicKey: .init(seedKey: seedKey,
                                                      derivedKey: derivedKey.publicKey,
                                                      derivationPath: blockchain.derivationPath),
                                     cardId: cardId)
    }
    
    /// Legacy wallet manager initializer
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    /// - Returns: WalletManager
    public func makeWalletManager(cardId: String, blockchain: Blockchain, walletPublicKey: Data) throws -> WalletManager {
        try makeWalletManager(from: blockchain,
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              cardId: cardId)
    }
    
    /// Wallet manager initializer for twin cards
    /// - Parameters:
    ///   - cardId: Card's cardId
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    ///   - walletPublicKey: Wallet's publicKey
    public func makeTwinWalletManager(from cardId: String, walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        try makeWalletManager(from: .bitcoin(testnet: isTestnet),
                              publicKey: .init(seedKey: walletPublicKey, derivedKey: nil, derivationPath: nil),
                              cardId: cardId,
                              pairPublicKey: pairKey,
                              tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           publicKey: Wallet.PublicKey,
                           cardId: String,
                           pairPublicKey: Data? = nil,
                           tokens: [Token] = []) throws -> WalletManager {
        if blockchain.curve == .ed25519, publicKey.seedKey.count > 32 || publicKey.blockchainKey.count > 32  {
            throw "Wrong key"
        }
        
        let addresses = blockchain.makeAddresses(from: publicKey.blockchainKey, with: pairPublicKey)
        let wallet = Wallet(blockchain: blockchain, addresses: addresses)
        
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey))
                providers.append(BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .btc, chain: testnet ? .test3: .main),
                                                              tokens: config.blockcypherTokens))
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .litecoin:
            return LitecoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockcypherNetworkProvider(endpoint: BlockcypherEndpoint(coin: .ltc, chain: .main), tokens: config.blockcypherTokens))
                providers.append(BlockchairNetworkProvider(endpoint: .litecoin, apiKey: config.blockchairApiKey))
                $0.networkService = BitcoinNetworkService(providers: providers)
            }
            
        case .dogecoin:
            return DogecoinWalletManager(wallet: wallet).then {
                var providers = [BitcoinNetworkProvider]()
                providers.append(BlockchairNetworkProvider(endpoint: .dogecoin, apiKey: config.blockchairApiKey))

                $0.networkService = DogecoinNetworkService(providers: providers)
            }
            
        case .ducatus:
            return DucatusWalletManager(wallet: wallet).then {
                $0.networkService = DucatusNetworkService()
            }
            
        case .stellar(let testnet):
            return StellarWalletManager(wallet: wallet, cardTokens: tokens).then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.stellarSdk = stellarSdk
                $0.networkService = StellarNetworkService(stellarSdk: stellarSdk)
            }
            
        case .ethereum(let testnet):
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let ethereumNetwork = testnet ? EthereumNetwork.testnet(projectId: config.infuraProjectId) : EthereumNetwork.mainnet(projectId: config.infuraProjectId)
                let jsonRpcProviders = [
                    EthereumJsonRpcProvider(network: ethereumNetwork),
                    EthereumJsonRpcProvider(network: .tangem)
                ]
                let blockchair = BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: ethereumNetwork, providers: jsonRpcProviders, blockchairProvider: blockchair)
            }
            
        case .rsk:
            return EthereumWalletManager(wallet: wallet, cardTokens: tokens).then {
                let blockchair = BlockchairNetworkProvider(endpoint: .bitcoin, apiKey: config.blockchairApiKey)
                $0.networkService = EthereumNetworkService(network: .rsk, providers: [EthereumJsonRpcProvider(network: .rsk)], blockchairProvider: blockchair)
            }
            
        case .bsc(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .bscTestnet : .bscMainnet
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockchairProvider: nil)
            }
            
        case .polygon(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .polygonTestnet : .polygon
                $0.networkService = EthereumNetworkService(network: network, providers: [EthereumJsonRpcProvider(network: network)], blockchairProvider: nil)
            }
            
        case .bitcoinCash:
            return BitcoinCashWalletManager(wallet: wallet).then {
                let provider = BlockchairNetworkProvider(endpoint: .bitcoinCash, apiKey: config.blockchairApiKey)
                $0.networkService = BitcoinCashNetworkService(provider: provider)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager(wallet: wallet, cardTokens: tokens).then {
                $0.networkService = BinanceNetworkService(isTestNet: testnet)
            }
            
        case .cardano:
            return CardanoWalletManager(wallet: wallet).then {
                let service = CardanoNetworkService(providers: [
                    AdaliteNetworkProvider(baseUrl: .main),
                    RosettaNetworkProvider(baseUrl: .tangemRosetta)
                ])
                $0.networkService = service
            }
            
        case .xrp:
            return XRPWalletManager(wallet: wallet).then {
                $0.networkService = XRPNetworkService()
            }
        case .tezos:
            return TezosWalletManager(wallet: wallet).then {
                $0.networkService = TezosNetworkService()
            }
            
        case .avalanche(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .avalancheTestnet : .avalanche
                $0.networkService = EthereumNetworkService(network: network,
                                                           providers: [EthereumJsonRpcProvider(network: network)],
                                                           blockchairProvider: nil)
            }
        }
    }
}
