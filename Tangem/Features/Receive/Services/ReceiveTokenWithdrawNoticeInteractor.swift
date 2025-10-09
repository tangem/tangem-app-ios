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
        let objectRepresentable: String

        switch tokenItem {
        case .blockchain(let network):
            objectRepresentable = "receive_shown_withdrawal_blockchain_\(network.blockchain.networkId)"
        case .token(let token, let blockchainNetwork):
            objectRepresentable = "receive_shown_withdrawal_token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"
        }

        let displayed = shownWithdrawalAlerts[objectRepresentable] ?? false
        shownWithdrawalAlerts[objectRepresentable] = true

        return !displayed
    }

    func markWithdrawalAlertShown(for tokenItem: TokenItem) {
        let objectRepresentable: String

        switch tokenItem {
        case .blockchain(let network):
            objectRepresentable = "receive_shown_withdrawal_blockchain_\(network.blockchain.networkId)"
        case .token(let token, let blockchainNetwork):
            objectRepresentable = "receive_shown_withdrawal_token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"
        }

        shownWithdrawalAlerts[objectRepresentable] = true
    }
}

private extension ReceiveTokenWithdrawNoticeInteractor {
    enum StorageKeys: String, RawRepresentable {
        case shownWithdrawalAlerts = "receive_shown_withdrawal_token_alerts"
    }
}
