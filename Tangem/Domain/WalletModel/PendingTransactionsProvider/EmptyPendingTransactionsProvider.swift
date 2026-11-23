//
//  EmptyPendingTransactionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

struct EmptyPendingTransactionsProvider: PendingTransactionsProvider {
    var pendingTransactions: [PendingTransactionRecord] { [] }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> { .just(output: []) }

    var hasBlockingPendingTransactions: Bool { false }
    var hasAnyBlockingPendingTransactions: Bool { false }
    var hasAnyBlockingPendingTransactionsPublisher: AnyPublisher<Bool, Never> { .just(output: false) }

    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel) {}
}
