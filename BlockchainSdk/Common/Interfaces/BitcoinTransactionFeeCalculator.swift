//
//  BitcoinTransactionFeeCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol BitcoinTransactionFeeCalculator {
    func calculateFee(satoshiPerByte: Int, amount: Decimal, destination: String) throws -> Fee
}
