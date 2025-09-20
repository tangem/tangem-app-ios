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

    @AppStorageCompat(StorageKeys.shownYieldModuleAlerts)
    private var shownYieldModuleAlerts: [String: Bool] = [:]

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

    /// Shows the yield module alert only once per token.
    /// - If the alert has already been shown (value is true or nil), return false.
    /// - On first show, mark both yield and withdrawal alerts as shown,
    ///   so withdrawal alert will never appear afterwards.
    func shouldShowYieldModuleAlert(for tokenItem: TokenItem) -> Bool {
        if case .token(let token, let blockchainNetwork) = tokenItem {
            let objectRepresentable = "yield_receive_shown_withdrawal_token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"

            guard shownYieldModuleAlerts[objectRepresentable] == false else {
                return false
            }

            let withdrawalKey = "receive_shown_withdrawal_token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"

            shownYieldModuleAlerts[objectRepresentable] = true
            shownWithdrawalAlerts[withdrawalKey] = true

            return true
        }

        return false
    }
}

private extension ReceiveTokenWithdrawNoticeInteractor {
    enum StorageKeys: String, RawRepresentable {
        case shownWithdrawalAlerts = "receive_shown_withdrawal_token_alerts"
        case shownYieldModuleAlerts = "yield_receive_shown_withdrawal_token_alerts"
    }
}
