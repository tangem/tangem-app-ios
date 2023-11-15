//
//  ExpressWallet.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExpressWallet {
    var currency: ExpressCurrency { get }
    var address: String { get }

    // Maybe will be deleted. We still deciding, How it will work
    var decimalCount: Int { get }

    func getBalance() async throws -> Decimal
}

public extension ExpressWallet {
    var contractAddress: String {
        currency.contractAddress
    }

    var network: String {
        currency.network
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
}
