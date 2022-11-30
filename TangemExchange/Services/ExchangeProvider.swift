//
//  ExchangeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeProvider {
    func fetchExchangeAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal
    func fetchQuote(items: ExchangeItems, amount: String) async throws -> QuoteData
    func fetchTxDataForExchange(items: ExchangeItems, walletAddress: String, amount: String) async throws -> ExchangeDataModel

    func approveTxData(for currency: Currency) async throws -> ExchangeApprovedDataModel
    func getSpenderAddress(for currency: Currency) async throws -> String
}
