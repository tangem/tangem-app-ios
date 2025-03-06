//
// SUIUtils.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

enum SUIUtils {
    static let suiGasBudgetScaleUpConstant = Decimal(stringValue: "1000000")!
    static let suiGasMinimumGasBudgetComputationUnits = Decimal(stringValue: "1000")!
    static let suiGasBudgetMaxValue = Decimal(stringValue: "50000000000")!

    enum EllipticCurveID: UInt8 {
        case ed25519 = 0x00
        case secp256k1 = 0x01
        case secp256r1 = 0x02

        var uint8: UInt8 {
            rawValue
        }
    }

    struct CoinType: Codable {
        let contract: String
        let lowerID: String
        let upperID: String

        var string: String {
            [contract, lowerID, upperID].joined(separator: Self.separator)
        }

        static let sui = Self(contract: "0x2", lowerID: "sui", upperID: "SUI")
        private static let separator = "::"

        init(contract: String, lowerID: String, upperID: String) {
            self.contract = contract
            self.lowerID = lowerID
            self.upperID = upperID
        }

        init(string: String) throws {
            let elements = string.components(separatedBy: Self.separator)

            guard elements.count == 3 else {
                throw SuiError.failedDecoding
            }

            contract = elements[0]
            lowerID = elements[1]
            upperID = elements[2]
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            try self.init(string: string)
        }

        func encode(to encoder: any Encoder) throws {
            try string.encode(to: encoder)
        }
    }
}
