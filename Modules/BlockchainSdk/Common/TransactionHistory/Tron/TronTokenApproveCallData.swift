//
//  TronTokenApproveCallData.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk

struct TronTokenApproveCallData {
    let spender: String
    let amount: BigUInt

    init?(calldata: String) {
        let bytes = [UInt8](Data(hexString: calldata))

        guard
            bytes.count == Constants.callDataLength,
            Data(bytes.prefix(Constants.methodIdLength)) == TronFunction.approve.prefix
        else {
            return nil
        }

        let spenderSlot = bytes.dropFirst(Constants.methodIdLength).prefix(Constants.slotLength)
        let padding = spenderSlot.prefix(Constants.paddingLength)
        let addressPrefix = spenderSlot.dropFirst(Constants.paddingLength).first
        let addressBody = spenderSlot.suffix(Constants.addressBodyLength)

        guard
            padding.allSatisfy({ $0 == 0 }),
            addressPrefix == 0 || addressPrefix == Constants.addressPrefix
        else {
            return nil
        }

        spender = ([Constants.addressPrefix] + addressBody).base58CheckEncodedString
        amount = BigUInt(Data(bytes.suffix(Constants.slotLength)))
    }
}

// MARK: - Constants

private extension TronTokenApproveCallData {
    enum Constants {
        static let methodIdLength = 4
        static let slotLength = 32
        static let paddingLength = 11
        static let addressBodyLength = 20
        static let addressPrefix: UInt8 = 0x41
        static let callDataLength = methodIdLength + slotLength * 2
    }
}
