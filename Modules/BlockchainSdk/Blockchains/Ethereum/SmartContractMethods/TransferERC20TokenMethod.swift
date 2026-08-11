//
//  TransferERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-20#transfer
public struct TransferERC20TokenMethod {
    public static let methodId = "0xa9059cbb"

    public let destination: String
    public let amount: BigUInt

    public init(destination: String, amount: BigUInt) {
        self.amount = amount
        self.destination = destination
    }

    public static func isEncodedCall(_ calldata: Data) -> Bool {
        calldata.starts(with: Data(hexString: methodId))
    }

    public static func isEncodedCall(_ calldata: String) -> Bool {
        isEncodedCall(Data(hexString: calldata))
    }
}

// MARK: - Decoding

public extension TransferERC20TokenMethod {
    /// Recovers the arguments of a `transfer(address,uint256)` call.
    /// Returns `nil` for anything that is not exactly such a call, including a call carrying
    /// a dirty address slot or a truncated or padded argument list.
    init?(calldata: Data) {
        guard Self.isEncodedCall(calldata) else {
            return nil
        }

        let arguments = calldata.dropFirst(Constants.methodIdLength)

        guard arguments.count == Constants.argumentsLength else {
            return nil
        }

        let destinationSlot = arguments.prefix(Constants.slotLength)
        let amountSlot = arguments.suffix(Constants.slotLength)

        guard destinationSlot.prefix(Constants.addressPaddingLength).allSatisfy({ $0 == 0 }) else {
            return nil
        }

        let destinationBytes = Data(destinationSlot.suffix(Constants.addressLength))

        self.init(destination: destinationBytes.hex().addHexPrefix(), amount: BigUInt(Data(amountSlot)))
    }
}

// MARK: - SmartContractMethod

extension TransferERC20TokenMethod: SmartContractMethod {
    public var methodId: String { Self.methodId }

    public var data: Data {
        let prefixData = Data(hexString: methodId)
        let addressData = Data(hexString: destination).leadingZeroPadding(toLength: Constants.slotLength)
        let amountData = amount.serialize().leadingZeroPadding(toLength: Constants.slotLength)
        return prefixData + addressData + amountData
    }
}

// MARK: - Constants

private extension TransferERC20TokenMethod {
    enum Constants {
        static let methodIdLength = 4
        static let slotLength = 32
        static let addressLength = 20
        static let addressPaddingLength = slotLength - addressLength
        static let argumentsLength = slotLength * 2
    }
}
