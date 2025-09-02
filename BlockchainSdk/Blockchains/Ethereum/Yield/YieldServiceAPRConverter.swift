//
//  YieldServiceAPYConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum YieldServiceAPYConverter {
    public static func convert(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hexString: hexString)

        guard data.count >= 96 else {
            throw YieldServiceError.unableToParseData
        }

        let aprValue = BigUInt(data.subdata(in: 64 ..< 96))

        guard let aprDecimal = aprValue.decimal else {
            throw YieldServiceError.unableToParseData
        }

        let apr = aprDecimal / Decimal(string: "1e27")!

        return (apr.exp(precision: 30) - 1) * 100
    }
}
