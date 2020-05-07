//
//  BinanceTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BinanceChain
import TangemSdk

class BinanceTransactionBuilder {
    var binanceWallet: BinanceWallet!
    private var message: Message?
    private let walletPublicKey: Data
    
    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        if isTestnet {
            binanceWallet.chainId = "Binance-Chain-Nile"
            binanceWallet.endpoint = BinanceChain.Endpoint.testnet.rawValue
        } else {
            binanceWallet.chainId = "Binance-Chain-Tigris"
            binanceWallet.endpoint = BinanceChain.Endpoint.mainnet.rawValue
        }
    }
    
    func buildForSign(amount: Decimal, targetAddress: String) -> Message {
        message = Message.transfer(symbol: "BNB", amount: Double("\(amount)")!, to: targetAddress, wallet: binanceWallet)
       return message!
    }
    
    func buildForSend(signature: Data, hash: Data) -> Message? {
        guard let normalizedSignature = Secp256k1Utils.normalizeVerify(
            secp256k1Signature: signature,
            hash: hash,
            publicKey: walletPublicKey) else {
            return nil
        }
        
        guard let message = message else {
            return nil
        }
        message.add(signature: normalizedSignature)
        return message
    }
}
