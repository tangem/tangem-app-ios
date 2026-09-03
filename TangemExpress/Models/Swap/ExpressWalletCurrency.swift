//
//  ExpressWalletCurrency.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressWalletCurrency: Hashable {
    public let contractAddress: String
    public let network: String
    public let decimalCount: Int
    public let symbol: String

    public var asCurrency: ExpressCurrency {
        .init(contractAddress: contractAddress, network: network)
    }

    public init(contractAddress: String, network: String, decimalCount: Int, symbol: String) {
        self.contractAddress = contractAddress
        self.network = network
        self.decimalCount = decimalCount
        self.symbol = symbol
    }

    public static func == (lhs: ExpressWalletCurrency, rhs: ExpressWalletCurrency) -> Bool {
        lhs.contractAddress == rhs.contractAddress
            && lhs.network == rhs.network
            && lhs.decimalCount == rhs.decimalCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress)
        hasher.combine(network)
        hasher.combine(decimalCount)
    }
}

// MARK: - Helpers

public extension ExpressWalletCurrency {
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
