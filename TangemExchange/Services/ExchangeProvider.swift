//
//  ExchangeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeProvider {
    func fetchAmountAllowance(for currency: Currency, walletAddress: String) async throws -> Decimal
    func fetchQuote(items: ExchangeItems, amount: String) async throws -> QuoteDataModel
    func fetchExchangeData(items: ExchangeItems, parameters: FetchExchangeDataParameters) async throws -> ExchangeDataModel

    func fetchApproveExchangeData(for currency: Currency) async throws -> ExchangeApprovedDataModel
    func fetchSpenderAddress(for currency: Currency) async throws -> String
}

struct FetchExchangeDataParameters {
    let walletAddress: String
    let amount: String
    let slippage: Int = 1
    let permit: String?
}
