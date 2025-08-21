//
//  ReceiveTokenWithdrawNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class ReceiveTokenWithdrawNoticeInteractor {
    // MARK: - Services

    @AppStorageCompat(StorageKeys.shownWithdrawalAlerts)
    private var shownWithdrawalAlerts: [String: Bool] = [:]

    // MARK: - Public Implementation

    func shouldShowWithdrawalAlert(for tokenItem: TokenItem) -> Bool {
        guard case .token(let token, let blockchainNetwork) = tokenItem else {
            return false
        }

        let objectRepresentable = "receive_shown_withdrawal_token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"

        let displayed = shownWithdrawalAlerts[objectRepresentable] ?? false
        shownWithdrawalAlerts[objectRepresentable] = true

        return !displayed
    }
}

private extension ReceiveTokenWithdrawNoticeInteractor {
    enum StorageKeys: String, RawRepresentable {
        case shownWithdrawalAlerts = "receive_shown_withdrawal_token_alerts"
    }
}
