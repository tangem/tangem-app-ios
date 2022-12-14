//
//  TransactionSenderMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange

struct TransactionSenderMock: TransactionSenderProtocol {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws {}
}
