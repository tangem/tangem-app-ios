//
//  TransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol TransactionHistoryRepository: Sendable {
    var exchangeHistoryUpdates: AsyncStream<[ExchangeHistoryRecord]> { get }
    var onrampHistoryUpdates: AsyncStream<[OnrampHistoryRecord]> { get }

    func syncInitial() async throws
    func syncDelta() async throws
}
