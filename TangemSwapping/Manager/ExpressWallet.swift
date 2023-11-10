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
    var decimalCount: Int { get }
    
    func getBalance() async throws -> Decimal
}

public extension ExpressWallet {
    var contactAddress: String {
        currency.contractAddress
    }
    
    var isToken: Bool {
        contactAddress != ExpressConstants.coinContractAddress
    }
    
    func convertToWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value * decimalValue
    }

    func convertFromWEI(value: Decimal) -> Decimal {
        let decimalValue = pow(10, decimalCount)
        return value / decimalValue
    }
}
