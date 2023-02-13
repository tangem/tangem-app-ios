//
//  BlockchainDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public protocol BlockchainDataProvider {
    func updateWallet() async throws
    func hasPendingTransaction(currency: Currency, to spenderAddress: String) -> Bool
    func getWalletAddress(currency: Currency) -> String?

    func getBalance(for currency: Currency) async throws -> Decimal
    func getBalance(for blockchain: ExchangeBlockchain) async throws -> Decimal
}
