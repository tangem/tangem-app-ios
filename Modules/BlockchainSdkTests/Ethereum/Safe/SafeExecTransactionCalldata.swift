//
//  SafeExecTransactionCalldata.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
@testable import BlockchainSdk

enum SafeExecTransactionCalldata {
    static let refundCap: BigUInt = 100_000_000_000_000
    static let refundReceiver = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"

    static func make(
        to: String,
        value: BigUInt,
        data: Data = Data(),
        operation: BigUInt = 0,
        gasToken: String = SafeGasToken.coinGasTokenRawValue
    ) -> String {
        let paddedData = padded(data.hex())
        let signatures = padded(String(repeating: "ab", count: Constants.signatureLength))
        let dataOffset = Constants.headWords * Constants.slotLength
        let signaturesOffset = dataOffset + Constants.slotLength + paddedData.count / 2

        return SafeExecTransactionMethod.methodId + [
            word(to),
            word(value),
            word(BigUInt(dataOffset)),
            word(operation),
            word(Constants.safeTxGas),
            word(Constants.baseGas),
            word(Constants.gasPrice),
            word(gasToken),
            word(refundReceiver),
            word(BigUInt(signaturesOffset)),
            word(BigUInt(data.count)),
            paddedData,
            word(BigUInt(Constants.signatureLength)),
            signatures,
        ].joined()
    }

    private static func word(_ value: BigUInt) -> String {
        let hex = String(value, radix: 16)
        return String(repeating: "0", count: Constants.wordHexLength - hex.count) + hex
    }

    private static func word(_ address: String) -> String {
        let hex = address.removeHexPrefix()
        return String(repeating: "0", count: Constants.wordHexLength - hex.count) + hex
    }

    private static func padded(_ hex: String) -> String {
        let remainder = hex.count % Constants.wordHexLength
        return remainder == 0 ? hex : hex + String(repeating: "0", count: Constants.wordHexLength - remainder)
    }
}

// MARK: - Constants

private extension SafeExecTransactionCalldata {
    enum Constants {
        static let headWords = 10
        static let slotLength = 32
        static let wordHexLength = 64
        static let signatureLength = 65
        static let safeTxGas: BigUInt = 50_000
        static let baseGas: BigUInt = 50_000
        static let gasPrice: BigUInt = 1_000_000_000
    }
}
