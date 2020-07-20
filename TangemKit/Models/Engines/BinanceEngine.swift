//
//  BinanceEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import BinanceChain

class BinanceEngine: CardEngine, PayIdProvider {
    let txBuilder: BinanceTransactionBuilder
    private var latestTxDate: Date?
    unowned var card: CardViewModel
    var binance: BinanceChain!
    private var hashesToSign: Data?
    var blockchainDisplayName: String {
        return card.tokenSymbol == nil ? "Binance" : "Binance asset"
    }
    
    var payIdManager: PayIdManager? = PayIdManager(network: .BNB)
    
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
    
    required init(card: CardViewModel) {
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
        txBuilder.binanceWallet = BinanceWallet(publicKey: Data(pubKeyCompressed))
        if card.isTestBlockchain {
            walletAddress = Bech32Internal().encode("tbnb", values: pubKeyHash)
            card.node = "testnet-dex.binance.org/"
            binance = BinanceChain(endpoint: BinanceChain.Endpoint.testnet)
            txBuilder.binanceWallet.chainId = "Binance-Chain-Nile"
            txBuilder.binanceWallet.endpoint = BinanceChain.Endpoint.testnet.rawValue
        } else {
            walletAddress = Bech32Internal().encode("bnb", values: pubKeyHash)
            card.node = "dex.binance.org/"
            binance = BinanceChain(endpoint: BinanceChain.Endpoint.mainnet)
            txBuilder.binanceWallet.chainId = "Binance-Chain-Tigris"
            txBuilder.binanceWallet.endpoint = BinanceChain.Endpoint.mainnet.rawValue
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
        return isExtractCoin ? .allowsFeeInclude : .none
    }
    
    var isExtractCoin: Bool {
        return card.tokenSymbol == nil || Decimal(string: card.walletTokenValue ?? "0") ?? 0 <= 0
    }
    
    func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        guard let amountValue = Decimal(string: amount),
            let feeValue = Decimal(string: fee) else {
                return nil
        }
        
        let finalAmount = includeFee && isExtractCoin ? amountValue - feeValue : amountValue
        let msg = txBuilder.buildForSign(amount: finalAmount, targetAddress: targetAddress, contractAddress: isExtractCoin ? nil : card.tokenContractAddress)
        let hash = msg.encodeForSignature()
        hashesToSign = hash
        return [hash]
    }
    
    private func getNormalizedVerifyedSignature(for sign: [UInt8], publicKey: [UInt8], hashToSign: [UInt8]) -> Data? {
        var vrfy: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_VERIFY)!
        defer {secp256k1_context_destroy(&vrfy)}
        var sig = secp256k1_ecdsa_signature()
        var normalizied = secp256k1_ecdsa_signature()
        _ = secp256k1_ecdsa_signature_parse_compact(vrfy, &sig, sign)
        _ = secp256k1_ecdsa_signature_normalize(vrfy, &normalizied, sig)
        
        var pubkey = secp256k1_pubkey()
        _ = secp256k1_ec_pubkey_parse(vrfy, &pubkey, publicKey, 65)
        if !secp256k1_ecdsa_verify(vrfy, normalizied, hashToSign, pubkey) {
            return nil
        }
        return Data(normalizied.data)
    }

    
    
    func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let hashes = self.hashesToSign, let normalizedSignature = getNormalizedVerifyedSignature(for: signFromCard, publicKey: card.walletPublicKeyBytesArray, hashToSign: hashes.bytes) else {
                       completion(false, "Failed to normalize sig" )
                                  return
               }
        
        
        guard let msg = txBuilder.buildForSend(signature: normalizedSignature) else {
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
        
        guard let _ = try? Bech32Internal().decode(address) else {
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
    var binanceWallet: BinanceWallet!
    private var message: Message?
    
    
    func buildForSign(amount: Decimal, targetAddress: String, contractAddress: String?) -> Message {
        let symbol = contractAddress ?? "BNB"
        message = Message.transfer(symbol: symbol, amount: Double("\(amount)")!, to: targetAddress, wallet: binanceWallet)
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
