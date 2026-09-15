//
//  SafeTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// The transaction a Safe's owners sign together — the exact fields the contract hashes, so nothing here may be
/// reshaped once a signature has been made over it.
public struct SafeTransaction: Hashable, Codable {
    public let to: String
    public let value: BigUInt
    public let data: Data
    /// `0` is CALL, the only kind a relayer executes.
    public let operation: Int
    public let safeTxGas: BigUInt
    public let baseGas: BigUInt
    public let gasPrice: BigUInt
    public let gasToken: String
    public let refundReceiver: String
    public let nonce: Int

    public init(
        to: String,
        value: BigUInt,
        data: Data,
        operation: Int,
        safeTxGas: BigUInt,
        baseGas: BigUInt,
        gasPrice: BigUInt,
        gasToken: String,
        refundReceiver: String,
        nonce: Int
    ) {
        self.to = to
        self.value = value
        self.data = data
        self.operation = operation
        self.safeTxGas = safeTxGas
        self.baseGas = baseGas
        self.gasPrice = gasPrice
        self.gasToken = gasToken
        self.refundReceiver = refundReceiver
        self.nonce = nonce
    }

    /// The inner call under the gas terms it was quoted with, at the Safe's current nonce.
    public init(innerCall: SafeInnerCall, feeParameters: SafeTransactionFeeParameters, nonce: Int) {
        self.init(
            to: innerCall.to,
            value: innerCall.value,
            data: innerCall.data,
            operation: Constants.callOperation,
            safeTxGas: feeParameters.safeTxGas,
            baseGas: feeParameters.baseGas,
            gasPrice: feeParameters.gasPrice,
            gasToken: feeParameters.gasToken.address,
            refundReceiver: feeParameters.refundReceiver,
            nonce: nonce
        )
    }
}

// MARK: - Convenience

public extension SafeTransaction {
    /// What the account pays for the network at most: the whole gas allowance at the price the members signed, in the
    /// smallest unit of `gasToken`. The Safe settles the executor's actual spend, which is never more.
    var fee: BigUInt {
        (safeTxGas + baseGas) * gasPrice
    }

    /// The call the Safe executes, apart from the gas terms and the nonce it was signed with.
    /// - Throws: `Error.unsupportedOperation` for anything but a CALL.
    var innerCall: SafeInnerCall {
        get throws {
            guard operation == Constants.callOperation else {
                throw Error.unsupportedOperation
            }

            return SafeInnerCall(to: to, value: value, data: data)
        }
    }
}

// MARK: - Auxiliary types

public extension SafeTransaction {
    enum Error: Swift.Error, Equatable {
        /// A delegatecall runs the code at `to` inside the Safe instead of calling it, so the fields say nothing about
        /// what the transaction does — reading it as a call would describe it as something it is not.
        case unsupportedOperation
    }
}

// MARK: - Constants

private extension SafeTransaction {
    enum Constants {
        static let callOperation = 0
    }
}
