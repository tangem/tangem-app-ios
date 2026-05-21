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
    public let newImplementation: String
    public let callData: Data

    public init(newImplementation: String, callData: Data) {
        self.newImplementation = newImplementation
        self.callData = callData
    }
}

extension UpgradeToAndCallMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `upgradeToAndCall(address,bytes)` method.
    public var methodId: String { "0x4f1ef286" }

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
