//
//  BinanceEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import BinanceChain

class BinanceEngine: CardEngine {
    let txBuilder: BinanceTransactionBuilder
    private var latestTxDate: Date?
    unowned var card: Card
    var binance: BinanceChain!
    
    var blockchainDisplayName: String {
        return "Binance"
    }
    
    var walletType: WalletType {
        return .binance 
    }
    
    var walletUnits: String {
        return "BNB"
    }
    
    var qrCodePreffix: String {
        return ""
    }
    
    var walletAddress: String = ""
    var exploreLink: String {
        return "https://explorer.binance.org/address/" + walletAddress
    }
    
    required init(card: Card) {
        self.card = card
        txBuilder = BinanceTransactionBuilder()
        if card.isWallet {
            setupAddress()
        }
  
        
    }
    
    func setupAddress() {
        guard let forRIPEMD160 = sha256(dataWithHexString(hex: pubKeyCompressed.toHexString())) else {
            assertionFailure()
            return
        }
        
        let pubKeyHash = RIPEMD160.hash(message: forRIPEMD160) 
        txBuilder.bnbWallet.compressedPublicKey = Data(pubKeyCompressed)
        if card.isTestBlockchain {
            walletAddress = Bech32().encode("tbnb", values: pubKeyHash)
            card.node = "testnet-dex.binance.org/"
            binance = BinanceChain(endpoint: BinanceChain.Endpoint.testnet)
            txBuilder.bnbWallet.chainId = "Binance-Chain-Nile"
            txBuilder.bnbWallet.endpoint = BinanceChain.Endpoint.testnet.rawValue
        } else {
            walletAddress = Bech32().encode("bnb", values: pubKeyHash)
            card.node = "dex.binance.org/"
            binance = BinanceChain(endpoint: BinanceChain.Endpoint.mainnet)
            txBuilder.bnbWallet.chainId = "Binance-Chain-Tigris"
            txBuilder.bnbWallet.endpoint = BinanceChain.Endpoint.mainnet.rawValue
        }
    }
    
    
}

extension BinanceEngine: CoinProvider {
    public var hasPendingTransactions: Bool {
        guard let txDate = latestTxDate else {
            return false
        }
        
        let sinceTxInterval = DateInterval(start: txDate, end: Date()).duration
        let expired = Int(sinceTxInterval) > 10
        if expired {
            latestTxDate = nil
            return false
        }
        return true
    }
    
    var coinTraitCollection: CoinTrait {
        return .allowsFeeInclude
    }
    
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        guard let amountValue = Decimal(string: amount),
            let feeValue = Decimal(string: fee) else {
                return nil
        }
        
        let finalAmount = includeFee ? amountValue - feeValue : amountValue
        let msg = txBuilder.buildForSign(amount: finalAmount, targetAddress: targetAddress)
        return [msg.encodeForSignature()]
    }
    
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let msg = txBuilder.buildForSend(signature: Data(signFromCard)) else {
            completion(false, "Failed to build tx" )
            return
        }
   
        binance.broadcast(message: msg, sync: true) {[weak self] (response) in
            if let error = response.error {
                completion(false, error)
                return
            }
            self?.latestTxDate = Date()
            completion(true, nil)
            print(response.broadcast)
        }
    }
    
    func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        binance.fees { response in
            let fees: [String] = response.fees.compactMap { fee -> String? in
                return fee.fixedFeeParams?.fee
            }
            
            guard let feeString = fees.first,
                let decimalfee = Decimal(string: feeString) else {
                completion(nil)
                return
            }
            
            let convertedFee = (decimalfee/Decimal(100000000)).rounded(blockchain: .binance)
            let fee = "\(convertedFee)"
            completion((fee,fee,fee))            
        }
    }
    
    func validate(address: String) -> Bool {
        if address.isEmpty {
            return false
        }
        
        guard let _ = try? Bech32().decode(address) else {
            return false
        }
        
        if !card.isTestBlockchain && !address.starts(with: "bnb1") {
            return false
        }
        
        if card.isTestBlockchain && !address.starts(with: "tbnb1") {
            return false
        }
        
        return true
    }
    
    func getApiDescription() -> String {
        return ""
    }
    
    
}

class BinanceTransactionBuilder {
    let bnbWallet = BNBWallet()
    private var message: Message?
    
    func buildForSign(amount: Decimal, targetAddress: String) -> Message {
        message = Message.transfer(symbol: "BNB", amount: (amount as NSDecimalNumber).doubleValue, to: targetAddress, wallet: bnbWallet)
       return message!
    }
    
    func buildForSend(signature: Data) -> Message? {
        guard let message = message else {
            return nil
        }
        message.add(signature: signature)
        return message
    }
}

class BNBWallet: Wallet {
    var compressedPublicKey: Data!
    override var publicKey: Data { compressedPublicKey }
    required init() {
        self.compressedPublicKey = Data()
        super.init()
    }
}
