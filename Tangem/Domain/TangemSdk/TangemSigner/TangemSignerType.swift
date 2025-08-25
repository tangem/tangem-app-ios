//
//  TangemSignerType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum TangemSignerType {
    case card
    case ring
    case mobileWallet

    var analyticsParameterValue: Analytics.ParameterValue {
        switch self {
        case .card:
            return Analytics.ParameterValue.card
        case .ring:
            return Analytics.ParameterValue.ring
        case .mobileWallet:
            return Analytics.ParameterValue.mobileWallet
        }
    }
}
