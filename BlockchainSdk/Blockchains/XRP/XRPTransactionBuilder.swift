//
//  XRPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import TangemFoundation

/// XRP transactions decoder https://fluxw42.github.io/ripple-tx-decoder/
class XRPTransactionBuilder {
    var account: String?
    let walletPublicKey: Data
    let curve: EllipticCurve

    private let utils: XRPAmountConverter

    init(walletPublicKey: Data, curve: EllipticCurve) throws {
        var key: Data
        switch curve {
        case .secp256k1:
            key = try Secp256k1Key(with: walletPublicKey).compress()
        case .ed25519, .ed25519_slip0010:
            key = [UInt8(0xED)] + walletPublicKey
        default:
            fatalError("unsupported curve")
        }
        self.walletPublicKey = key
        self.curve = curve
        utils = XRPAmountConverter(curve: curve)
    }

    private func sign(transaction: XRPTransaction) -> (XRPTransaction, Data) {
        let dataToSign = transaction.dataToSign(publicKey: walletPublicKey.hex())
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return (transaction, dataToSign)
        case .secp256k1:
            return (transaction, dataToSign.sha512Half())
        default:
            fatalError("unsupported curve")
        }
    }

    func buildTrustSetTransactionForSign(transaction: Transaction) throws -> (transaction: XRPTransaction, hash: Data) {
        let transaction = try buildTrustSetTransaction(from: transaction)
        let signed = sign(transaction: transaction)
        return signed
    }

    func buildForSign(transaction: Transaction, partialPaymentAllowed: Bool) throws -> (XRPTransaction, Data) {
        let transaction = try buildTransaction(from: transaction, partialPaymentAllowed: partialPaymentAllowed)
        return sign(transaction: transaction)
    }

    func buildForSend(transaction: XRPTransaction, signature: Data) throws -> String {
        var sig: Data
        switch curve {
        case .ed25519, .ed25519_slip0010:
            sig = signature
        case .secp256k1:
            sig = try Secp256k1Signature(with: signature).serializeDer()
        default:
            fatalError("unsupported curve")
        }

        let signedTx = try transaction.sign(signature: sig.toBytes)
        let blob = signedTx.getBlob()
        return blob
    }

    private func buildTransaction(from transaction: Transaction, partialPaymentAllowed: Bool) throws -> XRPTransaction {
        guard let account = account,
              let sequence = (transaction.params as? XRPTransactionParams)?.sequence
        else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let amountField = try constructAmountField(for: transaction)
        let feeDrops = utils.convertToDrops(amount: transaction.fee.amount.value)
        let decodedXAddress = try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress)
        let destination = decodedXAddress?.rAddress ?? transaction.destinationAddress

        let decodedTag = decodedXAddress?.tag
        let explicitTag = (transaction.params as? XRPTransactionParams)?.destinationTag

        let destinationTag: UInt32? = try {
            switch (decodedTag, explicitTag) {
            case (.some(let tag), .none):
                return tag
            case (.none, .some(let tag)):
                return tag
            case (.some(let tag1), .some(let tag2)):
                if tag1 != tag2 {
                    throw XRPError.distinctTagsFound
                }
                return tag1
            case (.none, .none): return nil
            }
        }()

        let params = XRPTransaction.PaymentParams(
            account: account,
            destination: destination,
            amount: amountField,
            fee: feeDrops,
            sequence: sequence,
            destinationTag: destinationTag,
            flags: partialPaymentAllowed ? [XRPTransaction.PaymentFlags.tfPartialPayment.rawValue] : nil
        )

        return XRPTransaction(params: params)
    }

    func buildTrustSetTransaction(from transaction: Transaction) throws -> XRPTransaction {
        guard let account = account,
              let sequence = (transaction.params as? XRPTransactionParams)?.sequence,
              case .token(let token) = transaction.amount.type
        else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
        let limitAmount = XRPTransaction.TrustSetParams.LimitAmount(currency: currency, issuer: issuer, value: Constants.trustlineMaxLimit)
        let feeInXrp = utils.convertToDrops(amount: transaction.fee.amount.value).rounded()

        let params = XRPTransaction.TrustSetParams(
            account: account,
            fee: feeInXrp,
            sequence: sequence,
            limitAmount: limitAmount,
            flags: [XRPTransaction.TrustsetFlag.tfSetNoRipple.rawValue]
        )

        return XRPTransaction(params: params)
    }

    private func constructAmountField(for transaction: Transaction) throws -> Any {
        switch transaction.amount.type {
        case .coin:
            let amountInDrops = utils.convertToDrops(amount: transaction.amount.value)
            return amountInDrops.decimalNumber.description(withLocale: Locale.posixEnUS)

        case .token(let token):
            let (currency, issuer) = try XRPAssetIdParser().getCurrencyCodeAndIssuer(from: token.contractAddress)
            let value = transaction.amount.value.decimalNumber.description(withLocale: Locale.posixEnUS)
            return ["currency": currency, "issuer": issuer, "value": value]

        case .feeResource, .reserve:
            assertionFailure("We cannot build transactions with fee resource or reserve amount")
            throw BlockchainSdkError.failedToBuildTx
        }
    }
}

// MARK: - Constants

private extension XRPTransactionBuilder {
    enum Constants {
        /// Maximum allowed trustline limit (XRP Ledger)
        /// https://xrpl.org/docs/references/protocol/data-types/currency-formats
        static let trustlineMaxLimit = "9999999999999999e80"
    }
}
