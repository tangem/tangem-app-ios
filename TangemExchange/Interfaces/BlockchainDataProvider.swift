//
//  BlockchainDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainDataProvider {
    func getWalletAddress(currency: Currency) -> String?

    func getBalance(blockchain: ExchangeBlockchain) async throws -> Decimal
    func getBalance(currency: Currency) async throws -> Decimal
    func getFiatBalance(currency: Currency, amount: Decimal) async throws -> Decimal
    func getFiatRateForFee(currency: Currency) async throws -> Decimal
}
