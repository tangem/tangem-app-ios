//
//  YieldServiceFeeRateConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum YieldServiceFeeRateConverter {
    public static func convert(_ result: String) throws -> BigUInt {
        let hexString = result.removeHexPrefix()
        
        let data = Data(hex: hexString)
            
        // ABI returns 32-byte word for uint256
        return BigUInt(data)
    }
}
