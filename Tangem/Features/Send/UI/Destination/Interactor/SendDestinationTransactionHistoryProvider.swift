//
//  SendDestinationTransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> { get }
}

class CommonSendDestinationTransactionHistoryProvider {
    private let transactionHistoryProvider: any WalletModelTransactionHistoryProvider

    init(transactionHistoryProvider: any WalletModelTransactionHistoryProvider) {
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

extension CommonSendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> {
        transactionHistoryProvider.transactionHistoryPublisher.map { state in
            guard case .loaded(let items) = state else {
                return []
            }

            return items
        }
        .eraseToAnyPublisher()
    }
}
