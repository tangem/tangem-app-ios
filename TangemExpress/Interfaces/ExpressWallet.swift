//
//  ExpressWallet.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    var expressCurrency: ExpressCurrency { get }
    var defaultAddress: String { get }
    var decimalCount: Int { get }

    func getBalance() throws -> Decimal
    func getCoinBalance() throws -> Decimal
}

public extension ExpressWallet {
    var contractAddress: String {
        expressCurrency.contractAddress
    }

    var network: String {
        expressCurrency.network
    }

    var isToken: Bool {
        contractAddress != ExpressConstants.coinContractAddress
    }

    // Maybe will be deleted. We still deciding, How it will work
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    // Maybe will be deleted. We still deciding, How it will work
    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }

    func availableForLoadFee() throws -> Bool {
        if isToken {
            return try getCoinBalance() > 0
        }

        return true
    }
}
