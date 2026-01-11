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
    func estimatedFee(provider: ExpressProvider, amount: Decimal) async throws -> ExpressFee.Variants
    func estimatedFee(provider: ExpressProvider, estimatedGasLimit: Int) async throws -> Fee
    func getFee(provider: ExpressProvider, amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants
}
