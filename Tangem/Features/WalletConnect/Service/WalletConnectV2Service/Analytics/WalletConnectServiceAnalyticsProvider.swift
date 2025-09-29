//
//  WalletConnectServiceAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletConnectServiceAnalyticsProvider {
    func logCompleteHandleSolanaALTTransactionRequest(isSuccess: Bool)
}

// MARK: - CommonWalletConnectServiceAnalyticsProvider

struct CommonWalletConnectServiceAnalyticsProvider: WalletConnectServiceAnalyticsProvider {
    func logCompleteHandleSolanaALTTransactionRequest(isSuccess: Bool) {
        Analytics.log(
            .walletConnectTransactionSolanaLargeStatus,
            params: [.status: .successOrFailed(for: isSuccess)]
        )
    }
}
