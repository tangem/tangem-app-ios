//
//  ExpressWalletCurrency.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressWalletCurrency: Hashable, Codable {
    public let contractAddress: String
    public let network: String
    public let decimalCount: Int

    public var asCurrency: ExpressCurrency {
        .init(contractAddress: contractAddress, network: network)
    }

    public init(contractAddress: String, network: String, decimalCount: Int) {
        self.contractAddress = contractAddress
        self.network = network
        self.decimalCount = decimalCount
    }

    public func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    public func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
