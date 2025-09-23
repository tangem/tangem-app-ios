//
//  YieldResponseMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

enum YieldResponseMapper {
    static func mapFeeRate(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hex: hexString)

        // ABI returns 32-byte word for uint256
        let feeRate = BigUInt(data)

        guard let feeRateDecimal = feeRate.decimal else {
            throw YieldServiceError.unableToParseData
        }

        return (feeRateDecimal * Constants.decimalBasisPoint) / Constants.decimalPercent
    }

    static func mapTokenData(_ result: String) throws -> YieldTokenData {
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

    static func mapAPY(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hexString: hexString)

        guard data.count >= 96 else {
            throw YieldServiceError.unableToParseData
        }

        let aprValue = BigUInt(data.subdata(in: 64 ..< 96))

        guard let aprDecimal = aprValue.decimal else {
            throw YieldServiceError.unableToParseData
        }

        let apr = aprDecimal / Constants.decimalRayUnit

        return (apr.exp() - Constants.decimalOne) * Constants.decimalPercent
    }
}

private extension YieldResponseMapper {
    enum Constants {
        static let decimalBasisPoint = Decimal(string: "0.01")!
        static let decimalRayUnit = Decimal(string: "1e27")!
        static let decimalPercent = Decimal(string: "100")!
        static let decimalOne = Decimal(string: "1")!
    }
}
