//
//  CurrencyWalletFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class CurrencyWalletFactory {
    public func makeWallet(from blockchain: Blockchain, address: String, token: Token?) -> CurrencyWallet {
        switch blockchain {
        case .bitcoin, .litecoin:
            let walletConfig = WalletConfig(allowFeeSelection: true, allowFeeInclusion: true)
            return CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
            
        case .ethereum, .rsk:
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            let wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
            if let token = token {
                wallet.add(amount: Amount(with: token))
            }
            return wallet
            
        case .stellar:
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: token == nil)
            let wallet = CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
            wallet.add(amount: Amount(with: blockchain, address: address, type: .reserve))
            if let token = token {
                wallet.add(amount: Amount(with: token))
            }
            return wallet
            
        case .bitcoinCash:
            let walletConfig = WalletConfig(allowFeeSelection: false, allowFeeInclusion: true)
            return CurrencyWallet(address: address, blockchain: blockchain, config: walletConfig)
        }
    }
}
