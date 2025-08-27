//
//  YieldSmartContractMethod.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

protocol YieldSmartContractMethod: SmartContractMethod { }

extension YieldSmartContractMethod {
    var data: Data {
        var data = Data(hex: methodId)
        
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            switch child.value {
            case let value as String:
                data.append(Data(hexString: value).leadingZeroPadding(toLength: 32))
            case let value as BigUInt:
                data.append(value.serialize().leadingZeroPadding(toLength: 32))
            default:
                BSDKLogger.warning("Unsupported type in SmartContractMethod")
            }
        }
        
        return data
    }
}
