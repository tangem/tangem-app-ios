//
//  PendingTransactionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol PendingTransactionsProvider {
    var pendingTransactions: [PendingTransactionRecord] { get }
    var pendingTransactionsPublisher: AnyPublisher<[PendingTransactionRecord], Never> { get }

    var hasBlockingPendingTransactions: Bool { get }
    /// Any pending transactions for the whole network. Coin, token, etc.
    var hasAnyBlockingPendingTransactions: Bool { get }
    var hasAnyBlockingPendingTransactionsPublisher: AnyPublisher<Bool, Never> { get }

    func setCryptoAccount(_ cryptoAccount: any CryptoAccountModel)
}
