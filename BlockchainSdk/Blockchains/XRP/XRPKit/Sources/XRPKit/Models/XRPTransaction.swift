//
//  XRPTransaction.swift
//  XRPKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

let HASH_TX_SIGN: [UInt8] = [0x53, 0x54, 0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73, 0x74, 0x78, 0x00]

class XRPTransaction {
    var fields: [String: Any] = [:]

    init(fields: [String: Any], autofill: Bool = false) {
        self.fields = enforceJSONTypes(fields: fields)
    }

    func dataToSign(publicKey: String) -> Data {
        // make sure all fields are compatible
        fields = enforceJSONTypes(fields: fields)

        // add account key to fields
        fields["SigningPubKey"] = publicKey as AnyObject

        // serialize transaction to binary
        let blob = Serializer().serializeTx(tx: fields, forSigning: true)

        // add the transaction prefix to the blob
        let data = Data(HASH_TX_SIGN) + blob

        return data
    }

    func sign(signature: [UInt8]) throws -> XRPTransaction {
        // make sure all fields are compatible
        fields = enforceJSONTypes(fields: fields)

        // create another transaction instance and add the signature to the fields
        let signedTransaction = XRPTransaction(fields: fields)
        signedTransaction.fields["TxnSignature"] = Data(signature).hex(.uppercase) as Any
        return signedTransaction
    }

    func getBlob() -> String {
        return Serializer().serializeTx(tx: fields, forSigning: false).hex(.uppercase)
    }

    func getJSONString() -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: fields, options: .prettyPrinted)
        return String(data: jsonData, encoding: .utf8)!
    }

    private func enforceJSONTypes(fields: [String: Any]) -> [String: Any] {
        let jsonData = try! JSONSerialization.data(withJSONObject: fields, options: .prettyPrinted)
        let fields = try! JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
        return fields as! [String: Any]
    }
}
