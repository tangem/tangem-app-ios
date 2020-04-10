//
//  XRPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class XRPTransactionBuilder {
    var account: String? = nil
    var sequence: Int? = nil
    let walletPublicKey: Data
    let curve: EllipticCurve
    
    internal init(walletPublicKey: Data, curve: EllipticCurve) {
        var key: Data
        switch curve {
        case .secp256k1:
            key = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        case .ed25519:
            key = [UInt8(0xED)] + walletPublicKey
        }
        self.walletPublicKey = key
        self.curve = curve
    }
    
    public func buildForSign(transaction: Transaction) -> Data? {
        guard let tx = buildTransaction(from: transaction) else {
            return nil
        }
        
        let dataToSign = tx.dataToSign(publicKey: walletPublicKey.asHexString())
        switch curve {
        case .ed25519:
            return dataToSign
        case .secp256k1:
            return dataToSign.sha512Half()
        }
    }
    
    public func buildForSend(transaction: Transaction,  signature: Data) -> String?  {
        guard let tx = buildTransaction(from: transaction) else {
            return nil
        }
        
        var sig: Data
        switch curve {
        case .ed25519:
            sig = signature
        case .secp256k1:
            guard let der = Secp256k1Utils.serializeToDer(secp256k1Signature: signature) else {
                return nil
            }
            
            sig = der
        }
        
        guard let signedTx = try? tx.sign(signature: sig.toBytes) else {
            return nil
        }
        
        let blob = signedTx.getBlob()
        return blob
    }
    
    private func buildTransaction(from transaction: Transaction) -> XRPTransaction? {
        guard let fee = transaction.fee?.value,
            let amount = transaction.amount.value,
            let account = account,
            let sequence = sequence else {
                return nil
        }
         
        let amountDrops = amount * Decimal(1000000)
        let feeDrops = fee * Decimal(1000000)
         
         
         // dictionary containing partial transaction fields
         let fields: [String:Any] = [
             "Account" : account,
             "TransactionType" : "Payment",
             "Destination" : transaction.destinationAddress,
             "Amount" : "\(amountDrops)",
             // "Flags" : UInt64(2147483648),
             "Fee" : "\(feeDrops)",
             "Sequence" : sequence,
         ]
         
         // create the transaction from dictionary
         return XRPTransaction(fields: fields)
    }
}
