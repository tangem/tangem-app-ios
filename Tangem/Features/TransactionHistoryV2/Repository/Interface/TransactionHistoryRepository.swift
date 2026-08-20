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
    func historyUpdates(for currency: ExpressCurrency) -> AsyncStream<[TransactionHistoryExpressExtraInfo]>
    func syncInitial() async throws
    func syncDelta() async throws
    func fetchNextPage() async throws
    func add(_ transaction: ExchangeTransaction) async throws
    func add(_ transaction: OnrampTransaction) async throws
}
