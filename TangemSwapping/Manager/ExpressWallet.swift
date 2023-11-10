//
//  ExpressWallet.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    func getBalance() async throws -> Decimal
    func getFee(destination: String, value: Decimal, hexData: String?) async throws -> [SwappingGasPricePolicy: Decimal]

    var currency: ExpressCurrency { get }
    var address: String { get }
    var decimalCount: Int { get }
}

public extension ExpressWallet {
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
