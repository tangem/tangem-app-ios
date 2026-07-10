//
//  YieldModuleSwapMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

/// Encodes a call to `swap(address tokenIn, uint256 amountIn, address target, address spender, bytes data)`.
public struct YieldModuleSwapMethod {
    public let tokenIn: String
    public let amountIn: BigUInt
    public let target: String
    public let spender: String
    public let swapData: Data

    public init(tokenIn: String, amountIn: BigUInt, target: String, spender: String, swapData: Data) {
        self.tokenIn = tokenIn
        self.amountIn = amountIn
        self.target = target
        self.spender = spender
        self.swapData = swapData
    }
}

extension YieldModuleSwapMethod: SmartContractMethod {
    /// - Note: First 4 bytes of Keccak-256 hash for the `swap(address,uint256,address,address,bytes)` method.
    public var methodId: String { "0x4c3f521d" }

    public var data: Data {
        var result = Data(hex: methodId)

        result.append(Data(hexString: tokenIn).leadingZeroPadding(toLength: 32))
        result.append(amountIn.serialize().leadingZeroPadding(toLength: 32))
        result.append(Data(hexString: target).leadingZeroPadding(toLength: 32))
        result.append(Data(hexString: spender).leadingZeroPadding(toLength: 32))
        result.append(BigUInt(UInt64(Constants.dynamicBytesOffset)).serialize().leadingZeroPadding(toLength: 32))

        result.append(BigUInt(UInt64(swapData.count)).serialize().leadingZeroPadding(toLength: 32))
        result.append(swapData)

        let padding = (32 - (swapData.count % 32)) % 32
        if padding > 0 {
            result.append(Data(repeating: 0, count: padding))
        }

        return result
    }
}

private extension YieldModuleSwapMethod {
    enum Constants {
        static let dynamicBytesOffset = 160
    }
}
