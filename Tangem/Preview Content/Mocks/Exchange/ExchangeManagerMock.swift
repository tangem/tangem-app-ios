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
    func updatePermit() {

    }

    func getExchangeItems() -> TangemExchange.ExchangeItems {
        ExchangeItems(source: .mock, destination: .mock, supportedPermit: true, permit: nil)
    }

    func getAvailabilityState() -> ExchangeAvailabilityState { .idle }

    func update(exchangeItems: ExchangeItems) {}

    func update(amount: Decimal?) {}

    func isEnoughAllowance() -> Bool { true }

    func refresh() {}
}
