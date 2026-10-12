//
//  TransactionHistoryEnricherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

enum TransactionHistoryEnricherFactory {
    static func make(for walletModel: some WalletModel) -> TransactionHistoryExpressDataEnriching.Factory {
        return { [weak walletModel] in
            try? await walletModel?
                .featuresPublisher
                .first()
                .async()
                .transactionHistoryProvider
        }
    }
}
