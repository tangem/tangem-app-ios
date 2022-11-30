//
//  BlockchainInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainInfoProvider {
    func getBalance(currency: Currency) async throws -> Decimal
    func getFee(currency: Currency, amount: Decimal, destination: String) async throws -> [Decimal]
}
