//
//  TransactionSenderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct TransactionSenderMock: TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws -> String { "" }
}

struct FiatRatesProviderMock: FiatRatesProviding {
    func getFiat(for currency: TangemExchange.Currency, amount: Decimal) async throws -> Decimal { .zero }
    func getFiat(for blockchain: TangemExchange.ExchangeBlockchain, amount: Decimal) async throws -> Decimal { .zero }
    func hasRates(for currency: Currency) -> Bool { false }
}
