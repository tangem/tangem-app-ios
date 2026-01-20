//
//  BalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressBalanceProvider = TangemExpress.BalanceProvider

public protocol BalanceProvider {
    func getBalance() throws -> Decimal
}

public enum ExpressBalanceProviderError: LocalizedError {
    case balanceNotFound

    public var errorDescription: String? {
        switch self {
        case .balanceNotFound: "Balance not found"
        }
    }
}
