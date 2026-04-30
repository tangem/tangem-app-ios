//
//  XRPTransaction.swift
//  XRPKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemFoundation

let HASH_TX_SIGN: [UInt8] = [0x53, 0x54, 0x58, 0x00]
let HASH_TX_SIGN_TESTNET: [UInt8] = [0x73, 0x74, 0x78, 0x00]

class XRPTransaction {
    var fields: [String: Any] = [:]

    init(fields: [String: Any], autofill: Bool = false) {
        self.fields = enforceJSONTypes(fields: fields)
    }

    init(params: XRPTransactionEncodable) {
        fields = params.toAnyDictionary()
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

protocol XRPTransactionEncodable {
    func toAnyDictionary() -> [String: Any]
}

extension XRPTransaction {
    enum TransactionType {
        static let trustSet = "TrustSet"
        static let payment = "Payment"
    }

    /// Flags used in XRPL TrustSet transactions.
    ///
    /// These flags control specific behaviors on the trust line, such as enabling or disabling rippling,
    /// setting authorization requirements, or freezing trust lines.
    /// Combine multiple flags using the bitwise OR (`|`) operator.
    enum TrustsetFlag: Int {
        /*
         - https://xrpl.org/docs/references/protocol/transactions/types/trustset#trustset-flags

         tfClearNoRipple    0x00040000    262144    Disable the No Ripple flag, allowing rippling on this trust line.
         tfSetNoRipple    0x00020000    131072    Enable the No Ripple flag, which blocks rippling between two trust lines of the same currency if this flag is enabled on both.
         */

        /// Disables the No Ripple flag on the trust line,
        /// allowing rippling (value transfer through this trust line).
        case tfClearNoRipple = 262144

        /// Enable the No Ripple flag
        case tfSetNoRipple = 131072
    }

    /// Transactions of the Payment type support additional values in the Flags field, as follows:
    enum PaymentFlags: Int {
        /**
         - https://xrpl.org/docs/references/protocol/transactions/types/payment#payment-flags

         tfPartialPayment    0x00020000    131072    If the specified Amount cannot be sent without spending more than SendMax, reduce the received amount instead of failing outright. See Partial Payments for more details.
         */
        case tfPartialPayment = 131072
    }

    /// Parameters for building a TrustSet transaction on the XRP Ledger
    struct TrustSetParams: XRPTransactionEncodable {
        /// Type of the transaction — always "TrustSet" for this struct
        let transactionType: String = TransactionType.trustSet
        /// XRP Ledger account address initiating the transaction
        let account: String
        /// Transaction fee in drops (1 drop = 0.000001 XRP).
        /// Typically, a standard fee of 10 drops is used for TrustSet transactions.
        let fee: Decimal
        /// Current account sequence number — must match the sender's sequence
        let sequence: Int
        /// Specifies the asset and limit to which this trust line applies
        let limitAmount: LimitAmount
        /// Integer bitmask for TrustSet flags (e.g. tfClearNoRipple)
        let flags: Set<Int>

        /// Represents the "LimitAmount" object in a TrustSet transaction
        /// This defines the asset to trust and the maximum amount trusted
        struct LimitAmount {
            /// The currency this trust line applies to.
            /// Must be a 3-letter ISO 4217 currency code or a 160-bit hex value (for tokens).
            /// "XRP" is invalid — trust lines cannot be created for XRP.
            let currency: String
            /// The issuer address of the token/currency being trusted
            let issuer: String
            /// Maximum amount of the token this account is willing to hold from the issuer.
            /// Typically set to a very high number like "9999999999999999e80".
            /// This is scientific notation (value × 10^exponent) used in XRP Ledger for large amounts.
            let value: String

            var asDictionary: [String: Any] {
                [
                    "currency": currency,
                    "issuer": issuer,
                    "value": value,
                ]
            }
        }

        // MARK: - XRPTransactionEncodable

        func toAnyDictionary() -> [String: Any] {
            [
                "TransactionType": transactionType,
                "Account": account,
                "Fee": fee.decimalNumber.description(withLocale: Locale.posixEnUS),
                "Sequence": sequence,
                "LimitAmount": limitAmount.asDictionary,
                "Flags": flags.reduce(0) { $0 | $1 },
            ]
        }
    }
}

extension XRPTransaction {
    struct PaymentParams: XRPTransactionEncodable {
        let account: String
        let destination: String
        let amount: Any
        let fee: Decimal
        let sequence: Int
        let destinationTag: UInt32?
        let flags: Set<Int>?

        // MARK: - XRPTransactionEncodable

        func toAnyDictionary() -> [String: Any] {
            let dict: [String: Any?] = [
                "Account": account,
                "TransactionType": TransactionType.payment,
                "Destination": destination,
                "Amount": amount,
                "Fee": fee.decimalNumber.description(withLocale: Locale.posixEnUS),
                "Sequence": sequence,
                "DestinationTag": destinationTag,
                "Flags": flags?.reduce(0) { $0 | $1 },
            ]

            return dict.compactMapValues { $0 }
        }
    }
}
