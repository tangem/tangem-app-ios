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
}
