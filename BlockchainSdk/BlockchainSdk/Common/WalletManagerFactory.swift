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
    public func makeWalletManager(from card: Card) -> WalletManager<CurrencyWallet>? {
        guard let blockchainName = card.cardData?.blockchainName,
            let curve = card.curve,
            let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve),
            let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId else {
                assertionFailure()
                return nil
        }
        
        let address = blockchain.makeAddress(from: walletPublicKey)
        let wallet = CurrencyWallet(address: address, blockchain: blockchain, token: getToken(from: card))
        
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BitcoinNetworkManager(address: address, isTestNet: testnet)
                $0.wallet = Variable(wallet)
            }
            
        case .litecoin:
            return LitecoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: false)
                $0.network = LitecoinNetworkManager(address: address, isTestNet: false)
                $0.wallet = Variable(wallet)
            }
            
        case .ducatus:
            return BitcoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: false)
                $0.network = DucatusNetworkManager(address: address)
                $0.wallet = Variable(wallet)
            }
            
        case .stellar(let testnet):
            return StellarWalletManager().then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.cardId = cardId
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = StellarNetworkManager(stellarSdk: stellarSdk)
                $0.wallet = Variable(wallet)
            }
            
        case .ethereum(let testnet):
            let ethereumNetwork = testnet ? EthereumNetwork.testnet : EthereumNetwork.mainnet
            return EthereumWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: ethereumNetwork)
                $0.network = EthereumNetworkManager(network: ethereumNetwork)
                $0.wallet = Variable(wallet)
            }
            
        case .rsk:
            return EthereumWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, network: .rsk)
                $0.network = EthereumNetworkManager(network: .rsk)
                $0.wallet = Variable(wallet)
            }
            
        case .bitcoinCash(let testnet):
            return BitcoinCashWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinCashTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BitcoinCashNetworkManager(address: address)
                $0.wallet = Variable(wallet)
            }
            
        case .binance(let testnet):
            return BinanceWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BinanceTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BinanceNetworkManager(address: address, isTestNet: testnet)
                $0.wallet = Variable(wallet)
            }
            
        case .cardano:
            return CardanoWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = CardanoTransactionBuilder(walletPublicKey: walletPublicKey)
                $0.network = CardanoNetworkManager()
                $0.wallet = Variable(wallet)
            }
            
        case .xrp(let curve):
            return XRPWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = XRPTransactionBuilder(walletPublicKey: walletPublicKey, curve: curve)
                $0.network = XRPNetworkManager()
                $0.wallet = Variable(wallet)
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
