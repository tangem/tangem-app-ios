//
//  SafeExecTransactionMethod.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct SafeExecTransactionMethod {
    static let methodId = "0x6a761202"

    private static let methodIdData = Data(hexString: methodId)

    let innerCall: SafeInnerCall
    let operation: Operation
    let gasToken: String
    let refundCap: BigUInt
}

// MARK: - Auxiliary types

extension SafeExecTransactionMethod {
    enum Operation: Int {
        case call
        case delegateCall
    }
}

// MARK: - Decoding

extension SafeExecTransactionMethod {
    init?(calldata: Data) {
        guard calldata.starts(with: Self.methodIdData) else {
            return nil
        }

        let arguments = Data(calldata.dropFirst(Self.methodIdData.count))

        guard
            let to = Self.address(in: arguments, word: 0),
            let value = Self.uint(in: arguments, word: 1),
            let dataOffset = Self.uint(in: arguments, word: 2).flatMap({ Int(exactly: $0) }),
            let data = Self.bytes(in: arguments, offset: dataOffset),
            let operation = Self.uint(in: arguments, word: 3).flatMap({ Int(exactly: $0) }).flatMap(Operation.init(rawValue:)),
            let safeTxGas = Self.uint(in: arguments, word: 4),
            let baseGas = Self.uint(in: arguments, word: 5),
            let gasPrice = Self.uint(in: arguments, word: 6),
            let gasToken = Self.address(in: arguments, word: 7)
        else {
            return nil
        }

        self.init(
            innerCall: SafeInnerCall(to: to, value: value, data: data),
            operation: operation,
            gasToken: gasToken,
            refundCap: (safeTxGas + baseGas) * gasPrice
        )
    }

    init?(calldata: String) {
        self.init(calldata: Data(hexString: calldata))
    }

    private static func slot(in arguments: Data, offset: Int) -> Data? {
        guard offset >= 0, offset <= arguments.count - Constants.slotLength else {
            return nil
        }

        return arguments.subdata(in: offset ..< offset + Constants.slotLength)
    }

    private static func uint(in arguments: Data, offset: Int) -> BigUInt? {
        slot(in: arguments, offset: offset).map { BigUInt($0) }
    }

    private static func uint(in arguments: Data, word: Int) -> BigUInt? {
        uint(in: arguments, offset: word * Constants.slotLength)
    }

    private static func address(in arguments: Data, word: Int) -> String? {
        guard
            let slot = slot(in: arguments, offset: word * Constants.slotLength),
            slot.prefix(Constants.addressPaddingLength).allSatisfy({ $0 == 0 })
        else {
            return nil
        }

        return Data(slot.suffix(Constants.addressLength)).hex().addHexPrefix()
    }

    private static func bytes(in arguments: Data, offset: Int) -> Data? {
        guard let length = uint(in: arguments, offset: offset).flatMap({ Int(exactly: $0) }) else {
            return nil
        }

        let start = offset + Constants.slotLength

        guard length <= arguments.count - start else {
            return nil
        }

        return arguments.subdata(in: start ..< start + length)
    }
}

// MARK: - Constants

private extension SafeExecTransactionMethod {
    enum Constants {
        static let slotLength = 32
        static let addressLength = 20
        static let addressPaddingLength = slotLength - addressLength
    }
}
