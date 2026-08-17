//
//  TangemPayFeeGroup.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum TangemPayFeeGroup: String, Decodable {
    case onramp = "ONRAMP"
    case atm = "ATM"
    case card = "CARD"
}
