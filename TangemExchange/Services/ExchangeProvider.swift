//
//  ExchangeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ExchangeProvider {
    func fetchExchangeAmountAllowance(for currency: Currency) async throws -> Decimal
    func fetchTxDataForExchange(items: ExchangeItems, amount: String, slippage: Int) async throws -> ExchangeDataModel

    func approveTxData(for currency: Currency) async throws -> ExchangeApprovedDataModel
    func getSpenderAddress(for currency: Currency) async throws -> String
}
