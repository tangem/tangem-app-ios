//
//  UpgradeToAndCallMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// Encodes a call to `upgradeToAndCall(address newImplementation, bytes memory data)`.
/// Used to atomically upgrade a proxy contract and invoke a function in a single transaction.
public struct UpgradeToAndCallMethod {
    public static let methodId = "0x4f1ef286"

    public let newImplementation: String
    public let callData: Data

    public init(newImplementation: String, callData: Data) {
        self.newImplementation = newImplementation
        self.callData = callData
    }

    public static func isEncodedCall(_ calldata: Data) -> Bool {
        calldata.starts(with: Data(hexString: methodId))
    }

    public static func isEncodedCall(_ calldata: String) -> Bool {
        isEncodedCall(Data(hexString: calldata))
    }

    /// Wraps a Yield Module call into `upgradeToAndCall` so the module is upgraded in the same transaction.
    ///
    /// The call is returned unchanged when there is no implementation to upgrade to
    /// or when it is already an `upgradeToAndCall` call.
    ///
    /// - Parameters:
    ///   - callData: Encoded call to the Yield Module.
    ///   - newImplementation: Address of the implementation to upgrade to, or `nil` when no upgrade is needed.
    /// - Returns: The wrapped call, or `callData` as is.
    public static func wrapIfNeeded(_ callData: Data, newImplementation: String?) -> Data {
        guard let newImplementation, !isEncodedCall(callData) else {
            return callData
        }

        return UpgradeToAndCallMethod(newImplementation: newImplementation, callData: callData).data
    }
}

// MARK: - Decoding

public extension UpgradeToAndCallMethod {
    /// Decodes an `upgradeToAndCall(address,bytes)` call back into the implementation address and the wrapped call.
    ///
    /// - Parameter calldata: Encoded transaction data.
    /// - Returns: `nil` when the data is not an `upgradeToAndCall` call or its ABI layout is malformed.
    init?(calldata: Data) {
        guard Self.isEncodedCall(calldata) else {
            return nil
        }

        let arguments = Data(calldata.dropFirst(Constants.methodIdLength))

        guard arguments.count >= Constants.headLength else {
            return nil
        }

        let implementationSlot = arguments.prefix(Constants.slotLength)

        guard implementationSlot.prefix(Constants.addressPaddingLength).allSatisfy({ $0 == 0 }) else {
            return nil
        }

        let offset = BigUInt(Data(arguments[Constants.slotLength ..< Constants.headLength]))

        guard offset <= BigUInt(arguments.count - Constants.slotLength) else {
            return nil
        }

        let lengthStart = Int(offset)
        let payloadStart = lengthStart + Constants.slotLength
        let length = BigUInt(Data(arguments[lengthStart ..< payloadStart]))

        guard length <= BigUInt(arguments.count - payloadStart) else {
            return nil
        }

        self.init(
            newImplementation: Data(implementationSlot.suffix(Constants.addressLength)).hex().addHexPrefix(),
            callData: Data(arguments[payloadStart ..< payloadStart + Int(length)])
        )
    }
}

extension UpgradeToAndCallMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `upgradeToAndCall(address,bytes)` method.
    public var methodId: String { Self.methodId }

    public var data: Data {
        var result = Data(hex: methodId)

        // 1. address — padded to 32 bytes
        result.append(Data(hexString: newImplementation).leadingZeroPadding(toLength: 32))

        // 2. offset to the dynamic `bytes` parameter (0x40 = 64, right after the two 32-byte head slots)
        var offsetData = Data(repeating: 0, count: 32)
        offsetData[31] = 0x40
        result.append(offsetData)

        // 3. length of the `bytes` payload
        var lengthData = Data(repeating: 0, count: 32)
        let length = callData.count
        lengthData[28] = UInt8((length >> 24) & 0xFF)
        lengthData[29] = UInt8((length >> 16) & 0xFF)
        lengthData[30] = UInt8((length >> 8) & 0xFF)
        lengthData[31] = UInt8(length & 0xFF)
        result.append(lengthData)

        // 4. actual bytes content, padded to a multiple of 32
        result.append(callData)
        let padding = (32 - (callData.count % 32)) % 32
        if padding > 0 {
            result.append(Data(repeating: 0, count: padding))
        }

        return result
    }
}

// MARK: - Constants

private extension UpgradeToAndCallMethod {
    enum Constants {
        static let methodIdLength = 4
        static let slotLength = 32
        static let addressLength = 20
        static let addressPaddingLength = slotLength - addressLength
        static let headLength = slotLength * 2
    }
}
