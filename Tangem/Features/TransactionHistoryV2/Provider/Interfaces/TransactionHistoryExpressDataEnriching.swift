//
//  TransactionHistoryExpressDataEnriching.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryExpressDataEnriching: Sendable {
    func enrich(with transaction: SentSwapTransactionData) async
    func enrich(with transaction: SentOnrampTransactionData) async
}
