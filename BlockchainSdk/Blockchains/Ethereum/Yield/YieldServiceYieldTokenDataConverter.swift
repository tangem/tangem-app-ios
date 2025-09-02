//
//  YieldServiceYieldTokenDataConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum YieldServiceYieldTokenDataConverter {
    public static func convert(_ result: String) throws -> YieldTokenData {
        let hexString = result.removeHexPrefix()

        let data = Data(hexString: hexString)

        guard data.count == 96 else {
            throw YieldServiceError.unableToParseData
        }

        let initializedData = data.subdata(in: 0 ..< 32)
        let activeData = data.subdata(in: 32 ..< 64)
        let maxNetworkFeeData = data.subdata(in: 64 ..< 96)

        let initialized = BigUInt(initializedData) != 0
        let active = BigUInt(activeData) != 0
        let maxNetworkFee = BigUInt(maxNetworkFeeData)

        return YieldTokenData(
            initialized: initialized,
            active: active,
            maxNetworkFee: maxNetworkFee
        )
    }
}

enum YieldServiceError: Error {
    case unableToParseData
}
