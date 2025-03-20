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
    private let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }
}

extension CommonSendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> {
        walletModel.transactionHistoryPublisher.map { state in
            guard case .loaded(let items) = state else {
                return []
            }

            return items
        }
        .eraseToAnyPublisher()
    }
}
