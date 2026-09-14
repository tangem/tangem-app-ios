//
//  TransactionHistoryRecordsReader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

protocol TransactionHistoryRecordsReader: Sendable {
    typealias Record = TransactionHistoryExpressExtraInfo

    func updates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[Record]>

    func fetchNextPage() async throws
}
