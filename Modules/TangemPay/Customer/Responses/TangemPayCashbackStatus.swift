//
//  TangemPayCashbackStatus.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayCashbackStatus: String, Codable, Equatable {
    case estimated
    case confirmed
    case excluded
    case awaitingCalculation = "awaiting_calculation"
    case undefined

    public init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: rawValue) ?? .undefined
    }
}
