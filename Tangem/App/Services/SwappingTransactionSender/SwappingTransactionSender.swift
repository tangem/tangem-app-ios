//
//  SwappingTransactionSender.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk

public protocol SwappingTransactionSender {
    func sendTransaction(_ info: SwappingTransactionData) async throws -> TransactionSendResult
}
