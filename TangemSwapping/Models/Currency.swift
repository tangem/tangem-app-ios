//
//  Currency.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct Currency {
    /// Currency ID, like `DAI` or `Ethereum`
    public let id: String

    /// Blockchain ID, only like `Ethereum`
    public let blockchain: SwappingBlockchain

    public let name: String
    public let symbol: String
    public let decimalCount: Int
    public let currencyType: CurrencyType

    public var contractAddress: String? {
        currencyType.contractAddress
    }

    public var isToken: Bool {
        currencyType.isToken
    }

    public init(
        id: String,
        blockchain: SwappingBlockchain,
        name: String,
        symbol: String,
        decimalCount: Int,
        currencyType: Currency.CurrencyType
    ) {
        self.id = id
        self.blockchain = blockchain
        self.name = name
        self.symbol = symbol
        self.decimalCount = decimalCount
        self.currencyType = currencyType
    }
}

extension Currency: Hashable {
    public static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public extension Currency {
    enum CurrencyType: Hashable {
        case coin
        case token(contractAddress: String)

        var isToken: Bool {
            if case .token = self {
                return true
            }

            return false
        }

        var contractAddress: String? {
            if case .token(let address) = self {
                return address
            }

            return nil
        }
    }
}

public extension Currency {
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
