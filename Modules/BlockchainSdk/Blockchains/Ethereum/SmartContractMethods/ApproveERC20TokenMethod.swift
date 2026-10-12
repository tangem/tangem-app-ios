//
//  ApproveERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// https://eips.ethereum.org/EIPS/eip-20#approve
public struct ApproveERC20TokenMethod {
    public static let methodId = "0x095ea7b3"

    private static let methodIdData = Data(hexString: methodId)

    public let spender: String
    public let amount: BigUInt

    public var isUnlimited: Bool { amount == .maxUInt256 }

    public init(spender: String, amount: BigUInt) {
        self.spender = spender
        self.amount = amount
    }

    public static func isEncodedCall(_ calldata: Data) -> Bool {
        calldata.starts(with: methodIdData)
    }

    public static func isEncodedCall(_ calldata: String) -> Bool {
        isEncodedCall(Data(hexString: calldata))
    }
}

// MARK: - Decoding

public extension ApproveERC20TokenMethod {
    init?(calldata: Data) {
        guard Self.isEncodedCall(calldata) else {
            return nil
        }

        let arguments = calldata.dropFirst(Constants.methodIdLength)

        guard arguments.count == Constants.argumentsLength else {
            return nil
        }

        let spenderSlot = arguments.prefix(Constants.slotLength)
        let amountSlot = arguments.suffix(Constants.slotLength)

        guard spenderSlot.prefix(Constants.addressPaddingLength).allSatisfy({ $0 == 0 }) else {
            return nil
        }

        let spenderBytes = Data(spenderSlot.suffix(Constants.addressLength))

        self.init(spender: spenderBytes.hex().addHexPrefix(), amount: BigUInt(Data(amountSlot)))
    }

    init?(calldata: String) {
        self.init(calldata: Data(hexString: calldata))
    }
}

// MARK: - SmartContractMethod

extension ApproveERC20TokenMethod: SmartContractMethod {
    public var methodId: String { Self.methodId }

    public var data: Data { defaultData() }
}

// MARK: - Constants

private extension ApproveERC20TokenMethod {
    enum Constants {
        static let methodIdLength = 4
        static let slotLength = 32
        static let addressLength = 20
        static let addressPaddingLength = slotLength - addressLength
        static let argumentsLength = slotLength * 2
    }
}
