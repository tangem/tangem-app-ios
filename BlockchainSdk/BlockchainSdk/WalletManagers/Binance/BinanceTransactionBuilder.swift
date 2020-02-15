//
//  BinanceTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BinanceChain

class BinanceTransactionBuilder {
    let bnbWallet = BNBWallet()
    var message: Message?
    let walletPublicKey: Data
    
    init(walletPublicKey: Data, isTestnet: Bool) {
        self.walletPublicKey = walletPublicKey
        if isTestnet {
            bnbWallet.chainId = "Binance-Chain-Nile"
            bnbWallet.endpoint = BinanceChain.Endpoint.testnet.rawValue
        } else {
            bnbWallet.chainId = "Binance-Chain-Tigris"
            bnbWallet.endpoint = BinanceChain.Endpoint.mainnet.rawValue
        }
    }
    
    func buildForSign(amount: Decimal, targetAddress: String) -> Message {
        message = Message.transfer(symbol: "BNB", amount: Double("\(amount)")!, to: targetAddress, wallet: bnbWallet)
       return message!
    }
    
    func buildForSend(signature: Data, hash: Data) -> Message? {
        guard let normalizedSignature = CryptoUtils.normalizeVerify(
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

class BNBWallet: BinanceWallet {
    var compressedPublicKey: Data!
    override var publicKey: Data { compressedPublicKey }
    required init() {
        self.compressedPublicKey = Data()
        super.init()
    }
}
