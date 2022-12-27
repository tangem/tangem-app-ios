//
//  ExchangeItems.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeItems {
    public var source: Currency
    public var destination: Currency?

    public var sourceBalance: Balance
    public var supportedPermit: Bool
    public var permit: String?

    public init(
        source: Currency,
        destination: Currency?,
        supportedPermit: Bool,
        permit: String?,
        sourceBalance: Balance = .zero
    ) {
        self.source = source
        self.destination = destination
        self.supportedPermit = supportedPermit
        self.permit = permit
        self.sourceBalance = sourceBalance
    }
}

public extension ExchangeItems {
    struct Balance {
        public static let zero = Balance(balance: 0, fiatBalance: 0)

        public let balance: Decimal
        public let fiatBalance: Decimal

        public init(balance: Decimal, fiatBalance: Decimal) {
            self.balance = balance
            self.fiatBalance = fiatBalance
        }
    }
}
