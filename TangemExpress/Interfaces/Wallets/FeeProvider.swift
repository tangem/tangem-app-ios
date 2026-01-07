//
//  FeeProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public typealias ExpressFeeProvider = FeeProvider

public protocol FeeProvider {
    func estimatedFee(amount: Decimal) async throws -> Fee
    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee
    func getFee(amount: ExpressAmount, destination: String) async throws -> Fee
}
