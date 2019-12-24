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
        guard let blockchainName = card.cardData?.blockchainName, let walletPublicKey = card.walletPublicKey else {
            assertionFailure()
            return nil
        }
        
        if blockchainName.contains("btc") || blockchainName.contains("bitcoin") {
            let walletConfig = WalletConfig(allowFeeSelection: true, allowFeeInclusion: true)
            return BitcoinWalletManager(cardId: card.cardId, walletPublicKey: walletPublicKey, walletConfig: walletConfig, isTestnet: blockchainName.contains("test") )
        }
        
        if blockchainName.contains("xlm") {
            let token = getToken(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            return StellarWalletManager(cardId: card.cardId, walletPublicKey: walletPublicKey, walletConfig: walletConfig, token: token, isTestnet: blockchainName.contains("test"))
        }
        
        if blockchainName.contains("eth") {
            let token = getToken(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            return EthereumWalletManager(cardId: card.cardId, walletPublicKey: walletPublicKey, walletConfig: walletConfig, token: token, isTestnet: blockchainName.contains("test"))
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
