//
//  TronTokenTransferCallData.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk

struct TronTokenTransferCallData {
    let recipient: String
    let amount: BigUInt

    init?(calldata: String) {
        let bytes = [UInt8](Data(hexString: calldata))

        guard
            bytes.count == Constants.callDataLength,
            Data(bytes.prefix(Constants.methodIdLength)) == TronFunction.transfer.prefix
        else {
            return nil
        }

        let recipientSlot = bytes.dropFirst(Constants.methodIdLength).prefix(Constants.slotLength)
        let padding = recipientSlot.prefix(Constants.paddingLength)
        let addressPrefix = recipientSlot.dropFirst(Constants.paddingLength).first
        let addressBody = recipientSlot.suffix(Constants.addressBodyLength)

        guard
            padding.allSatisfy({ $0 == 0 }),
            addressPrefix == 0 || addressPrefix == Constants.addressPrefix
        else {
            return nil
        }

        recipient = ([Constants.addressPrefix] + addressBody).base58CheckEncodedString
        amount = BigUInt(Data(bytes.suffix(Constants.slotLength)))
    }
}

// MARK: - Constants

private extension TronTokenTransferCallData {
    enum Constants {
        static let methodIdLength = 4
        static let slotLength = 32
        static let paddingLength = 11
        static let addressBodyLength = 20
        static let addressPrefix: UInt8 = 0x41
        static let callDataLength = methodIdLength + slotLength * 2
    }
}
