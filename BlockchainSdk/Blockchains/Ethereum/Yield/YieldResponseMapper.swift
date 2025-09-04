//
//  YieldResponseMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum YieldResponseMapper {
    public static func mapFeeRate(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hex: hexString)

        // ABI returns 32-byte word for uint256
        let feeRate = BigUInt(data)

        guard let feeRateDecimal = feeRate.decimal else {
            throw YieldServiceError.unableToParseData
        }

        return (feeRateDecimal * Constants.basisPoint) / Decimal(stringValue: "100")!
    }

    public static func mapTokenData(_ result: String) throws -> YieldTokenData {
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

    public static func mapAPY(_ result: String) throws -> Decimal {
        let hexString = result.removeHexPrefix()

        let data = Data(hexString: hexString)

        guard data.count >= 96 else {
            throw YieldServiceError.unableToParseData
        }

        let aprValue = BigUInt(data.subdata(in: 64 ..< 96))

        guard let aprDecimal = aprValue.decimal else {
            throw YieldServiceError.unableToParseData
        }

        let apr = aprDecimal / Constants.rayUnit

        return (apr.exp(precision: 30) - 1) * 100
    }
    
    public static func mapBalances(protocolBalance: String, effectiveBalance: String) -> YieldBalances {
        let effectiveBalanceValue = BigUInt(Data(hexString: protocolBalance))
        let protocolBalanceValue = BigUInt(Data(hexString: effectiveBalance))

        return YieldBalances(
            effective: effectiveBalanceValue,
            protocol: protocolBalanceValue
        )
    }
}

extension YieldResponseMapper {
    enum Constants {
        static let basisPoint = Decimal(string: "0.01")!
        static let rayUnit = Decimal(string: "1e27")!
    }
}
