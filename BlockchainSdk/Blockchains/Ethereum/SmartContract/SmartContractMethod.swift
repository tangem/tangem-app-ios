//
//  SmartContractMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public protocol SmartContractMethod {
    var methodId: String { get }
    var data: Data { get }
}

public extension SmartContractMethod {
    /// The hex data with the `0x` prefix. Use it for send as `data` in the `eth_call`
    var encodedData: String {
        data.hex().addHexPrefix()
    }

    /// Default implementation that encodes method id and parameters.
    func defaultData() -> Data {
        var data = Data(hex: methodId)

        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            switch child.value {
            case let value as String:
                data.append(Data(hexString: value).leadingZeroPadding(toLength: 32))
            case let value as BigUInt:
                data.append(value.serialize().leadingZeroPadding(toLength: 32))
            case let value:
                BSDKLogger.warning("Unsupported type \(value.self) in SmartContractMethod")
            }
        }

        return data
    }
}
