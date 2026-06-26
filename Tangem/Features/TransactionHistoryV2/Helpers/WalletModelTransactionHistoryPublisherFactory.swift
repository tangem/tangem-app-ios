//
//  WalletModelTransactionHistoryPublisherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation

enum WalletModelTransactionHistoryPublisherFactory {
    static func makeTransactionHistoryPublisher(
        transactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        featuresPublisher: some Publisher<[WalletModelFeature], Never>,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never> {
        guard FeatureProvider.isAvailable(.transactionHistoryV2) else {
            return transactionHistoryPublisher.eraseToAnyPublisher()
        }

        return featuresPublisher
            .map(\.transactionHistoryProvider)
            .removeDuplicates { $0?.id.toAnyHashable() == $1?.id.toAnyHashable() }
            .flatMapLatest { provider -> AnyPublisher<WalletModelTransactionHistoryState, Never> in
                // No provider (unsupported chain) -> emit the unenriched on-chain history.
                guard let provider else {
                    return transactionHistoryPublisher.eraseToAnyPublisher()
                }

                return provider.bridgedTransactionHistoryPublisher(
                    transactionHistoryPublisher: transactionHistoryPublisher,
                    feeTokenItem: feeTokenItem
                )
            }
            .eraseToAnyPublisher()
    }
}
