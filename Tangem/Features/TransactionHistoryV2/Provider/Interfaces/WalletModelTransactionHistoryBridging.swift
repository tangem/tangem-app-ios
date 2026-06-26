//
//  WalletModelTransactionHistoryBridging.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Bridges the provider's Express/Onramp transaction history into the wallet model's on-chain history stream.
protocol WalletModelTransactionHistoryBridging {
    func bridgedTransactionHistory(
        transactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never>
}
