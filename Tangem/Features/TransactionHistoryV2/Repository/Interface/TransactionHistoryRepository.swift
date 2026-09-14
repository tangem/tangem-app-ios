//
//  TransactionHistoryRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

/// Owns the express history of a single user wallet: one synced feed shared by all of its wallet models.
protocol TransactionHistoryRepository: Sendable {
    func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]>

    func fetchNextPage() async throws

    func syncInitial() async throws
    func syncDelta() async throws
    func add(_ transaction: ExchangeTransaction) async throws
    func add(_ transaction: OnrampTransaction) async throws
}
