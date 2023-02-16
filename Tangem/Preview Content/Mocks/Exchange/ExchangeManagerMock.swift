//
//  ExchangeManagerMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExchange

struct ExchangeManagerMock: ExchangeManager {
    func setDelegate(_ delegate: TangemExchange.ExchangeManagerDelegate) {}

    func getExchangeItems() -> TangemExchange.ExchangeItems {
        ExchangeItems(source: .mock, destination: .mock)
    }

    func getAvailabilityState() -> ExchangeAvailabilityState { .idle }

    func getReferrerAccount() -> ExchangeReferrerAccount? { nil }

    func update(exchangeItems: ExchangeItems) {}

    func update(amount: Decimal?) {}

    func isEnoughAllowance() -> Bool { true }

    func refresh(type: ExchangeManagerRefreshType) {}

    func didSendApprovingTransaction(exchangeTxData: ExchangeTransactionDataModel) {}
    func didSendSwapTransaction(exchangeTxData: ExchangeTransactionDataModel) {}
}
