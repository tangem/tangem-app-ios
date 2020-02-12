//
//  BlockchainFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import RxSwift

public class CurrencyWalletManagerFactory {
    let walletFactory = CurrencyWalletFactory()
    
    public func makeWalletManager(from card: Card) -> AnyWalletManager<CurrencyWallet>? {
        guard let blockchainName = card.cardData?.blockchainName,
            let blockchain = Blockchain.from(blockchainName: blockchainName),
            let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId else {
            assertionFailure()
            return nil
        }
        
        let token = getToken(from: card)
        let address = blockchain.makeAddress(from: walletPublicKey)
        let wallet = walletFactory.makeWallet(from: blockchain, address: address, token: token)
        
        switch blockchain {
        case .bitcoin(let testnet):
            return BitcoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = BitcoinNetworkManager(address: address, isTestNet: testnet)
                $0.wallet = Variable(wallet)
            }.eraseToAnyWalletManager()
            
        case .litecoin:
            return LitecoinWalletManager().then {
                $0.cardId = cardId
                $0.txBuilder = BitcoinTransactionBuilder(walletAddress: address, walletPublicKey: walletPublicKey, isTestnet: false)
                $0.network = LitecoinNetworkManager(address: address, isTestNet: false)
                $0.wallet = Variable(wallet)
            }.eraseToAnyWalletManager()
            
        case .stellar(let testnet):
             return StellarWalletManager().then {
                let url = testnet ? "https://horizon-testnet.stellar.org" : "https://horizon.stellar.org"
                let stellarSdk = StellarSDK(withHorizonUrl: url)
                $0.cardId = cardId
                $0.stellarSdk = stellarSdk
                $0.txBuilder = StellarTransactionBuilder(stellarSdk: stellarSdk, walletPublicKey: walletPublicKey, isTestnet: testnet)
                $0.network = StellarNetworkManager(stellarSdk: stellarSdk)
                $0.wallet = Variable(wallet)
            }.eraseToAnyWalletManager()
            
        case .ethereum(let testnet):
            return EthereumWalletManager().then {
                 $0.cardId = cardId
                 $0.txBuilder = EthereumTransactionBuilder(walletPublicKey: walletPublicKey, isTestnet: testnet)
                 $0.network = EthereumNetworkManager()
                 $0.wallet = Variable(wallet)
            }.eraseToAnyWalletManager()
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

public struct Token {
    let currencySymbol: String
    let contractAddress: String
    let decimalCount: Int
}
