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
            let asset = getAsset(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: asset == nil)
            return StellarWalletManager(cardId: card.cardId, walletPublicKey: walletPublicKey, walletConfig: walletConfig, asset: asset, isTestnet: blockchainName.contains("test"))
        }
        
        if blockchainName.contains("eth") {
            let asset = getAsset(from: card)
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: asset == nil)
            return EthereumWalletManager(cardId: card.cardId, walletPublicKey: walletPublicKey, walletConfig: walletConfig, asset: asset, isTestnet: blockchainName.contains("test"))
        }
        return nil
    }
    
    private func getAsset(from card: Card) -> Token? { //gettoken
        if let symbol = card.cardData?.tokenSymbol,
            let contractAddress = card.cardData?.tokenContractAddress,
            let decimals = card.cardData?.tokenDecimal {
            return Token(symbol: symbol, contractAddress: contractAddress, decimals: decimals)
        }
        return nil
    }
}

struct Token { //token rename
    let symbol: String
    let contractAddress: String
    let decimals: Int
}
