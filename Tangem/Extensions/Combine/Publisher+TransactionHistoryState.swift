//
//  Publisher+TransactionHistoryState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

extension Publisher where Output == WalletModelTransactionHistoryState, Failure == Never {
    /// A refresh empties the stored history before fetching, so an empty or failed response leaves nothing
    /// on screen. Drop those emissions while the previously delivered state still carries transactions.
    /// The list changes again on the next response that carries transactions, or when the chain stops
    /// supporting history at all.
    func retainingContent() -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        scan((retained: WalletModelTransactionHistoryState?.none, output: WalletModelTransactionHistoryState?.none)) { accumulated, new in
            guard
                case .loaded(let retainedItems)? = accumulated.retained,
                retainedItems.isNotEmpty,
                new.preservesPreviousContent
            else {
                return (retained: new, output: new)
            }

            return (retained: accumulated.retained, output: nil)
        }
        .compactMap(\.output)
        .eraseToAnyPublisher()
    }
}
