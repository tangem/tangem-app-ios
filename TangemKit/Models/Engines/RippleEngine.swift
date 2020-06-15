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
    let provider = MoyaProvider<XrpTarget>(plugins: [NetworkLoggerPlugin()])
    let payIdProvider = MoyaProvider<PayIdTarget>(plugins: [NetworkLoggerPlugin()])
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
    
    private func resolveAddressAndCheckCreated(_ address: String, completion: @escaping (String?, Bool?, Error?) -> Void) {
        if address.contains(find: "$") { //pay id
            payIdProvider.request(.address(payId: address)) { moyaResult in
                switch moyaResult {
                case .success(let response):
                    if let payIdResponse = try? response.map(PayIdResponse.self) {
                        if let resolvedAddress = payIdResponse.addresses?.compactMap({ address -> String? in
                            if address.paymentNetwork == "XRPL" && address.environment == "MAINNET" {
                                return address.addressDetails?.address
                            }
                            return nil
                        }).first, self.validate(address: resolvedAddress) {
                            let resolvedAddressDecoded = (try? XRPAddress.decodeXAddress(xAddress: resolvedAddress))?.rAddress ?? resolvedAddress
                            self.checkTargetAccountCreated(resolvedAddressDecoded) { result in
                                completion(resolvedAddress, result, nil)
                            }
                        } else {
                            print("Unknown address format in PayID response")
                            completion(nil, nil, "Unknown address format in PayID response")
                        }
                    } else {
                        print("Unknown response format on PayID request")
                        completion(nil, nil, "Unknown response format on PayID request")
                    }
                    
                case .failure(let error):
                    let err = "PayID request failed. \(error.localizedDescription)"
                    print(err)
                    completion(nil, nil, err)
                }
            }
        } else {
            let addressDecoded = (try? XRPAddress.decodeXAddress(xAddress: address))?.rAddress ?? address
            checkTargetAccountCreated(addressDecoded) { result in
                completion(address, result, nil)
            }
        }
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
        
        
        resolveAddressAndCheckCreated(targetAddress) {[weak self] destinationAddress, isAccountCreated, error in
            guard let self = self, let isAccountCreated = isAccountCreated, let destinationAddress = destinationAddress else {
                completion(nil, error)
                return
            }
            
            var destination: String
            var destinationTag: UInt32? = nil
            
            //X-address
            let decodedXAddress = try? XRPAddress.decodeXAddress(xAddress: destinationAddress)
            if decodedXAddress != nil {
                destination = decodedXAddress!.rAddress
                destinationTag = decodedXAddress!.tag
            } else {
                destination = destinationAddress
            }
            
            if !isAccountCreated && finalAmountDecimal < reserve {
                completion(nil, "Target account is not created. Amount to send should be \(stringReserve) XRP + fee or more")
                return
            }
            
            // dictionary containing partial transaction fields
            var fields: [String:Any] = [
                "Account" : account,
                "TransactionType" : "Payment",
                "Destination" : destination,
                "Amount" : "\(amountDrops)",
                // "Flags" : UInt64(2147483648),
                "Fee" : "\(feeDrops)",
                "Sequence" : sequence,
            ]
            
            if destinationTag != nil {
                fields["DestinationTag"] = destinationTag
            }
            
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
        if address.isEmpty {
            return false
        }
        
        if address.contains("$") { // PayID
            let addressParts = address.split(separator: "$")
            if addressParts.count != 2 {
                return false
            }
            let addressURL = "https://" + addressParts[1] + "/" + addressParts[0]
            if let _ = URL(string: addressURL) {
                return true
            } else {
                return false
            }
        }
        
        if XRPSeedWallet.validate(address: address) {
            return true
        }
        
        if let _ = try? XRPAddress.decodeXAddress(xAddress: address) {
            return true
        }
        
        return false
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


extension RippleEngine: PayIdProvider {
    func loadPayId(cid: String, key: Data, completion: @escaping (Result<String?, Error>) -> Void) {
        payIdProvider.request(.getPayId(cid: cid, cardPublicKey: key)) { moyaResult in
            DispatchQueue.main.async {
                switch moyaResult {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                        if let getResponse = try? response.map(GetPayIdResponse.self) {
                            if let payId = getResponse.payId {
                                completion(.success(payId))
                            } else {
                                completion(.failure("Empty PayId response"))
                            }
                        } else {
                            completion(.failure("Unknown PayId response"))
                        }
                    } catch {
                        if response.statusCode == 404 {
                            completion(.success(nil))
                            return
                        } else {
                            completion(.failure("PayId request failed"))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createPayId(cid: String, key: Data, payId: String, address: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        payIdProvider.request(.createPayId(cid: cid, cardPublicKey: key, payId: payId, address: address, network: .XRPL)) { moyaResult in
            DispatchQueue.main.async {
                switch moyaResult {
                case .success(let response):
                    do {
                        _ = try response.filterSuccessfulStatusCodes()
                          completion(.success(true))
                    } catch {
                           completion(.failure("PayId request failed"))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    
}
