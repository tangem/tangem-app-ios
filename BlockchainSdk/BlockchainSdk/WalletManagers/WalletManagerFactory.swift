//
//  BlockchainFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class WalletManagerFactory {
    public func makeWalletManager(from card: Card) -> WalletManager? {
        guard let blockchainName = card.cardData?.blockchainName, let walletPublicKey = card.walletPublicKey,
            let cardId = card.cardId else {
            assertionFailure()
            return nil
        }
        let isTestnet = blockchainName.contains("test")
        
        if blockchainName.contains("btc") || blockchainName.contains("bitcoin") {
            let walletConfig = WalletConfig(allowFeeSelection: true, allowFeeInclusion: true)
            return BitcoinWalletManager(cardId: cardId,
                                        walletPublicKey: walletPublicKey,
                                        walletConfig: walletConfig,
                                        blockchain: .bitcoin(testnet: isTestnet)  )
        }
        
        if blockchainName.contains("xlm") {
            let token = getToken(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            return StellarWalletManager(cardId: cardId,
                                        walletPublicKey: walletPublicKey,
                                        walletConfig: walletConfig,
                                        token: token,
                                        blockchain: .stellar(testnet: isTestnet))
        }
        
        if blockchainName.contains("eth") {
            let token = getToken(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            return EthereumWalletManager(cardId: cardId,
                                         walletPublicKey: walletPublicKey,
                                         walletConfig: walletConfig,
                                         token: token,
                                         blockchain: .ethereum(testnet: isTestnet))
        }
        return nil
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
