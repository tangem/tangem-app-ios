//
//  TransactionHistoryRecordsStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol TransactionHistoryRecordsStorage: Sendable {
    typealias Record = TransactionHistoryExpressExtraInfo

    func updates(for currency: ExpressCurrency) -> AsyncStream<[TransactionHistoryExpressExtraInfo]>
    func save(_ transactions: [ExchangeTransaction]) async throws
    func save(_ transactions: [OnrampTransaction]) async throws
    func fetchNextPage() async throws
    func clear() async throws
}
