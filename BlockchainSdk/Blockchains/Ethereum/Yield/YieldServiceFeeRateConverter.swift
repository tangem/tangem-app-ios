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
    public static func convert(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hex: hexString)

        // ABI returns 32-byte word for uint256
        let feeRate = BigUInt(data)

        guard let feeRateDecimal = feeRate.decimal else {
            throw YieldServiceError.unableToParseData
        }

        return (feeRateDecimal * Constants.basisPoint) / Decimal(stringValue: "100")!
    }
}

extension YieldServiceFeeRateConverter {
    enum Constants {
        static let basisPoint = Decimal(string: "0.01")!
    }
}
