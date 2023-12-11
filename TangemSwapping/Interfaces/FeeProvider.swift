//
//  FeeProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressFee {
    case single(Fee)
    case double(market: Fee, fast: Fee)

    var value: Decimal {
        switch self {
        case .single(let fee):
            return fee.amount.value
        case .double(let market, _):
            return market.amount.value
        }
    }
}

public protocol FeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee
    func getFee(amount: Decimal, destination: String, hexData: String?) async throws -> ExpressFee
}
