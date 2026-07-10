//
//  WalletModelTransactionHistoryEnriching.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Enriches the wallet model's on-chain transaction history stream with the provider's Express/Onramp transaction history.
protocol WalletModelTransactionHistoryEnriching {
    func enrichedTransactionHistoryPublisher(
        from originalTransactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        feeTokenItem: TokenItem
    ) -> AnyPublisher<WalletModelTransactionHistoryState, Never>
}
