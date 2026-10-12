//
//  TransactionHistoryProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol TransactionHistoryProviding:
    Identifiable,
    TransactionHistorySyncing,
    TransactionHistoryExpressDataEnriching {
    var mappingQueue: DispatchQueue { get }

    func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]>
}
