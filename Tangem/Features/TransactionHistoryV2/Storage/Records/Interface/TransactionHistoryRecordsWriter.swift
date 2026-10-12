//
//  TransactionHistoryRecordsWriter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol TransactionHistoryRecordsWriter: Sendable {
    func save(_ transactions: [ExchangeTransaction]) async throws
    func save(_ transactions: [OnrampTransaction]) async throws
}
