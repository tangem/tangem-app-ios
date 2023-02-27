//
//  TransactionSendable.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

public protocol TransactionSendable {
    func sendTransaction(_ info: ExchangeTransactionDataModel) async throws -> TransactionSendResult
}
