//
//  RippleEngine.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
import CryptoSwift
import Moya

public class RippleEngine: CardEngine {
    let provider = MoyaProvider<XrpTarget>(plugins: [NetworkLoggerPlugin(verbose: true)])
    unowned public var card: CardViewModel
    
    public var blockchainDisplayName: String {
        return "Ripple"
    }
    
    public var walletReserve: String?
    public var walletType: WalletType {
        return .ripple
    }
    
    public var walletUnits: String {
        return "XRP"
    }
    
    public var qrCodePreffix: String {
        return "ripple:"
    }
    
    public var walletAddress: String = ""
    public var exploreLink: String {
        return "https://xrpscan.com/account/" + walletAddress
    }
    
    var accountInfo: XrpAccountData?
    var unsignedTransaction: XRPTransaction?
    var unconfirmedBalance: String?
    var confirmedBalance: String?
    
    public required init(card: CardViewModel) {
        self.card = card
        if card.isWallet {
            setupAddress()
        }
    }
    
    var canonicalPubKey: [UInt8] {
        switch card.curveID {
        case .secp256k1:
            return pubKeyCompressed
        case .ed25519:
            return [0xED] + card.walletPublicKeyBytesArray
        }
    }
    
    public func setupAddress() {
        let canonicalPubKey = self.canonicalPubKey
        guard canonicalPubKey.count == 33 else {
            assertionFailure()
            return
        }
        
        guard let forRIPEMD160 = sha256(dataWithHexString(hex: canonicalPubKey.toHexString())) else {
            assertionFailure()
            return
        }
        
        let input = RIPEMD160.hash(message: forRIPEMD160).bytes
        
        let buffer = [0x00] + input 
        let checkSum = Array(buffer.sha256().sha256()[0..<4])
        
        walletAddress = String(base58Encoding: Data(bytes: buffer + checkSum), alphabet: Base58String.xrpAlphabet)
        
        card.node = "explorer2.adalite.io"
    }
    
}


extension RippleEngine: CoinProvider, CoinProviderAsync {
    public var hasPendingTransactions: Bool {
        confirmedBalance != unconfirmedBalance
    }
    
    public var coinTraitCollection: CoinTrait {
        .all
    }
    
    private func checkTargetAccountCreated(_ address: String, completion: @escaping (Bool?) -> Void) {
        provider.request(.accountInfo(account: address)) { result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result else {
                    completion(nil)
                    return
                }
                
                if let code = xrpResult.error_code, code == 19 {
                    completion(false)
                    return
                } else {
                    completion(true)
                    return
                }
                
            case .failure(let error):
                print(error)
                completion(nil)
            }
        }
    }
    
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String, completion: @escaping ([Data]?, Error?) -> Void) {
        guard let amountDecimal = Decimal(string: amount),
            let feeDecimal = Decimal(string: fee),
            let account = self.accountInfo?.account,
            let sequence = self.accountInfo?.sequence,
            let stringReserve = walletReserve,
            let reserve = Decimal(string: stringReserve) else {
                completion(nil, nil)
                return
        }
        
        let finalAmountDecimal = includeFee ? amountDecimal - feeDecimal : amountDecimal
        let amountDrops = finalAmountDecimal * Decimal(1000000)
        let feeDrops = feeDecimal * Decimal(1000000)
        
        
        checkTargetAccountCreated(targetAddress) {[weak self] isAccountCreated in
            guard let self = self, let isAccountCreated = isAccountCreated else {
                completion(nil, nil)
                return
            }
            
            if !isAccountCreated && finalAmountDecimal < reserve {
                completion(nil, "Target account is not created. Amount to send should be \(stringReserve) XRP + fee or more")
                return
            }
            
            // dictionary containing partial transaction fields
            let fields: [String:Any] = [
                "Account" : account,
                "TransactionType" : "Payment",
                "Destination" : targetAddress,
                "Amount" : "\(amountDrops)",
                // "Flags" : UInt64(2147483648),
                "Fee" : "\(feeDrops)",
                "Sequence" : sequence,
            ]
            
            // create the transaction from dictionary
            let partialTransaction = XRPTransaction(fields: fields)
            self.unsignedTransaction = partialTransaction
            let dataToSign = partialTransaction.dataToSign(publicKey: self.canonicalPubKey.hexString)
            switch self.card.curveID {
            case .ed25519:
                completion([dataToSign], nil)
            case .secp256k1:
                completion([dataToSign.sha512Half()], nil)
            }
        }
    }
    
    
    public func getHashForSignature(amount: String, fee: String, includeFee: Bool, targetAddress: String) -> [Data]? {
        return nil
    }
    
    public func sendToBlockchain(signFromCard: [UInt8], completion: @escaping (Bool, Error?) -> Void) {
        guard let tx = self.unsignedTransaction else {
            completion(false, "Missing tx")
            return
        }
        
        var signature: [UInt8]
        switch card.curveID {
        case .ed25519:
            signature = signFromCard
        case .secp256k1:
            guard let der = serializeToDer(secp256k1Signature: Data(signFromCard)) else {
                completion(false, "Error der serialization")
                return
            }
            
            signature = der
        }
        
        guard let signedTx = try? tx.sign(signature: signature) else {
            completion(false, "Failed to sign tx")
            return
        }
        let blob = signedTx.getBlob()
        provider.request(.submit(tx: blob)) {[weak self] result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result,
                    let code = xrpResult.engine_result_code else {
                        completion(false, "Submit error")
                        return
                }
                
                if code != 0 {
                    let message = xrpResult.engine_result_message ?? "Failed to send"
                    completion(false, message)
                    return
                }
                
                self?.unconfirmedBalance = nil
                completion(true,nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    public func getFee(targetAddress: String, amount: String, completion: @escaping ((min: String, normal: String, max: String)?) -> Void) {
        provider.request(.fee) { result in
            switch result {
            case .success(let response):
                guard let xrpResult = (try? response.map(XrpResponse.self))?.result,
                    let minFee = xrpResult.drops?.minimum_fee,
                    let normalFee = xrpResult.drops?.open_ledger_fee,
                    let maxFee = xrpResult.drops?.median_fee,
                    let minFeeDecimal = Decimal(string: minFee),
                    let normalFeeDecimal = Decimal(string: normalFee),
                    let maxFeeDecimal = Decimal(string: maxFee)  else {
                        completion(nil)
                        return
                }
                
                let min = minFeeDecimal/Decimal(1000000)
                let normal = normalFeeDecimal/Decimal(1000000)
                let max = maxFeeDecimal/Decimal(1000000)
                
                let fee = ("\(min.rounded(blockchain: .ripple))",
                    "\(normal.rounded(blockchain: .ripple))",
                    "\(max.rounded(blockchain: .ripple))")
                completion(fee)
            case .failure(let error):
                Analytics.log(error: error)
                print(error.localizedDescription)
                completion(nil)
            }
        }
    }
    
    public func validate(address: String) -> Bool {
        return XRPWallet.validate(address: address)
    }
    
    public func getApiDescription() -> String {
        ""
    }
    
    
    private func serializeToDer(secp256k1Signature sign: Data) -> [UInt8]? {
        var ctx: secp256k1_context = secp256k1_context_create(.SECP256K1_CONTEXT_NONE)!
        defer {secp256k1_context_destroy(&ctx)}
        var sig = secp256k1_ecdsa_signature()
        var normalized = secp256k1_ecdsa_signature()
        guard secp256k1_ecdsa_signature_parse_compact(ctx, &sig, Array(sign)) else { return nil }
        
        _ = secp256k1_ecdsa_signature_normalize(ctx, &normalized, sig)
        var length: UInt = 128
        var der = [UInt8].init(repeating: UInt8(0x0), count: Int(length))
        guard secp256k1_ecdsa_signature_serialize_der(ctx, &der, &length, normalized)  else { return nil }
        
        return Array(der[0..<Int(length)])
    }
}
