//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol FeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee
    func getFee(amount: Decimal, destination: String, hexData: Data?) async throws -> ExpressFee
}

public enum ExpressFee {
    case single(Fee)
    case double(market: Fee, fast: Fee)

    var fastest: Fee {
        switch self {
        case .single(let fee):
            return fee
        case .double(_, let fast):
            return fast
        }
    }
}
