//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class WalletManagerFactory {
    private let config: BlockchainSdkConfig
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    public func makeWalletManagers(for wallet: CardWallet, cardId: String, blockchains: [Blockchain]) -> [WalletManager] {
        blockchains.compactMap { makeWalletManager(from: cardId, wallet: wallet, blockchain: $0) }
    }
    
    public func makeWalletManagers(from card: Card, blockchainsProvider: (CardWallet) -> [Blockchain]) -> [WalletManager] {
        guard let cardId = card.cardId else { return [] }
        
        return card.wallets.reduce([]) { (managers: [WalletManager], wallet) in
            var mangs = managers
            mangs.append(contentsOf:
                blockchainsProvider(wallet).compactMap {
                    makeWalletManager(from: cardId, wallet: wallet, blockchain: $0)
                }
            )
            return mangs
        }
    }
    
    /// Base wallet manager constructor
    /// - Parameters:
    ///   - card: Tangem card
    ///   - blockchain: blockhain to create. If nil, card native blockchain will be used
    /// - Returns: WalletManager?
    public func makeWalletManager(from cardId: String, wallet: CardWallet, blockchain: Blockchain) -> WalletManager? {
        guard let walletPublicKey = wallet.publicKey,
              let curve = wallet.curve else {
            return nil
        }
        
        return makeWalletManager(from: blockchain,
                                 walletPublicKey: walletPublicKey,
                                 cardId: cardId,
                                 cardCurve: curve,
                                 walletPairPublicKey: nil,
                                 tokens: [])
    }
    
    public func makeTwinWalletManager(from cardId: String, wallet: CardWallet, blockchain: Blockchain, pairKey: Data) -> WalletManager? {
        guard
            let pubkey = wallet.publicKey,
            let curve = wallet.curve
        else { return nil }
        
        return makeWalletManager(from: blockchain,
                                 walletPublicKey: pubkey,
                                 cardId: cardId,
                                 cardCurve: curve,
                                 walletPairPublicKey: pairKey,
                                 tokens: [])
    }
    
    func makeWalletManager(from blockchain: Blockchain,
                           walletPublicKey: Data,
                           cardId: String,
                           cardCurve: EllipticCurve,
                           walletPairPublicKey: Data? = nil,
                           tokens: [Token] = []) -> WalletManager? {
        guard blockchain.curve == cardCurve else { return nil }
        
        let addresses = blockchain.makeAddresses(from: walletPublicKey, with: walletPairPublicKey)
        let wallet = Wallet(blockchain: blockchain,
                            addresses: addresses)
        
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
            
        case .matic(let testnet):
            return EthereumWalletManager(wallet: wallet).then {
                let network: EthereumNetwork = testnet ? .maticTestnet : .maticMainnet
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
        }
    }
}
