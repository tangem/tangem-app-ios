//
//  TransactionSenderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct TransactionSenderMock: TransactionSenderProtocol {
    func sendPermissionTransaction(_ info: ExchangeTransactionInfo, gasPrice: Decimal) async throws {

    }

    func sendExchangeTransaction(_ info: ExchangeTransactionInfo, gasValue: Decimal, gasPrice: Decimal) async throws {

    }
}
