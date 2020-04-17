//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import RxSwift

public class WalletManagerFactory {
    public init() {}
    
    public func makeWalletManager(from card: Card) -> WalletManager<CurrencyWallet>? {
        guard let blockchainName = card.cardData?.blockchainName,
            let curve = card.curve,
            let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve),
            let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId,
            let productMask = card.cardData?.productMask else {
                assertionFailure()
                return nil
        }
        
        let address = blockchain.makeAddress(from: walletPublicKey)
        let token = getToken(from: card)
        
        switch blockchain {
        case .bitcoin(let testnet):
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://blockchain.info/address/\(address)")!,
                                        shareString: "bitcoin:\(address)")
            
            return BitcoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BitcoinNetworkManager(address: address, isTestNet: testnet)
                $0.wallet = wallet
            }
            
        case .litecoin:
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://live.blockcypher.com/ltc/address/\(address)")!,
                                        shareString: "litecoin:\(address)")
            
            return LitecoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: false)
                $0.network = LitecoinNetworkManager(address: address, isTestNet: false)
                $0.wallet = wallet
            }
            
        case .ducatus:
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://insight.ducatus.io/#/DUC/mainnet/address/\(address)")!)
            
            return BitcoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: false)
                $0.network = DucatusNetworkManager(address: address)
                $0.wallet = wallet
            }
            
        case .stellar(let testnet):
            let baseUrl = testnet ? "https://stellar.expert/explorer/testnet/account/" : "https://stellar.expert/explorer/public/account/"
            let exploreLink =  baseUrl + address
            
            let walletType: WalletType = blockchainName == "xlm-tag" || productMask.contains(.tag) ? .nft : .default
            
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: exploreLink)!,
                                        shareString: "sharePrefix\(address)",
                                        token: token,
                                        walletType: walletType)
            
            
            return StellarWalletManager().then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.cardId = cardId
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = StellarNetworkManager(stellarSdk: stellarSdk)
                $0.wallet = wallet
            }
            
        case .ethereum(let testnet):
            let sharePrefix = testnet ? "" : "ethereum:"
            let baseUrl = testnet ? "https://rinkeby.etherscan.io/address/" : "https://etherscan.io/address/"
            let exploreLink = token == nil ? baseUrl + address :
            "https://etherscan.io/token/\(token!.contractAddress)?a=\(address)"
            
            let walletType: WalletType = blockchainName == "nfttoken" || (token?.currencySymbol.contains("nft", ignoreCase: true) ?? false) ?
                .nft : .default
            
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: exploreLink)!,
                                        shareString: "\(sharePrefix)\(address)",
                                        token: token,
                                        walletType: walletType)
            
            let ethereumNetwork = testnet ? EthereumNetwork.testnet : EthereumNetwork.mainnet
            return EthereumWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: ethereumNetwork)
                $0.network = EthereumNetworkManager(network: ethereumNetwork)
                $0.wallet = wallet
            }
            
        case .rsk:
            var exploreLink = "https://explorer.rsk.co/address/\(address)"
            if token != nil {
                exploreLink += "?__tab=tokens"
            }
            
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: exploreLink)!,
                                        shareString: nil,
                                        token: token)
            
            return EthereumWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: .rsk)
                $0.network = EthereumNetworkManager(network: .rsk)
                $0.wallet = wallet
            }
            
        case .bitcoinCash(let testnet):
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://blockchair.com/bitcoin-cash/address/\(address)")!)
            
            return BitcoinCashWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinCashTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BitcoinCashNetworkManager(address: address)
                $0.wallet = wallet
            }
            
        case .binance(let testnet):
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://explorer.binance.org/address/\(address)")!)
            
            return BinanceWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BinanceTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BinanceNetworkManager(address: address, isTestNet: testnet)
                $0.wallet = wallet
            }
            
        case .cardano:
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://cardanoexplorer.com/address/\(address)")!)
            
            return CardanoWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: walletPublicKey)
                $0.network = CardanoNetworkManager()
                $0.wallet = wallet
            }
            
        case .xrp(let curve):
            let wallet = CurrencyWallet(blockchain: blockchain,
                                        address: address,
                                        exploreUrl: URL(string: "https://xrpscan.com/account/\(address)")!,
                                        shareString: "ripple:\(address)")
            
            return XRPWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = XRPTransactionBuilder(walletPublicKey: walletPublicKey, curve: curve)
                $0.network = XRPNetworkManager()
                $0.wallet = wallet
            }
        }
    }
    
    private func getToken(from card: Card) -> Token? {
        if let symbol = card.cardData?.tokenSymbol,
            let contractAddress = card.cardData?.tokenContractAddress,
            let decimals = card.cardData?.tokenDecimal {
            return Token(currencySymbol: symbol, contractAddress: contractAddress, decimalCount: decimals)
        }
        return nil
    }
}
