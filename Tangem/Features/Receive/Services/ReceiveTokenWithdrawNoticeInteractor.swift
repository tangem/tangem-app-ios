//
//  ReceiveTokenWithdrawNoticeInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol ReceiveTokenWithdrawNoticeInteractor {
    func shouldShowWithdrawalAlert(for tokenItem: TokenItem) -> Bool
}

extension ReceiveTokenWithdrawNoticeInteractor {
    static func noticeKey(for tokenItem: TokenItem) -> String {
        switch tokenItem {
        case .blockchain(let network):
            "blockchain_\(network.blockchain.networkId)"
        case .token(let token, let blockchainNetwork):
            "token_\(token.contractAddress)_\(blockchainNetwork.blockchain.networkId)"
        }
    }
}

final class GeneralReceiveTokenWithdrawNoticeInteractor: ReceiveTokenWithdrawNoticeInteractor {
    // MARK: - Services

    @AppStorageCompat(StorageKeys.shownWithdrawalAlerts)
    private var shownWithdrawalAlerts: [String: Bool] = [:]

    // MARK: - Public Implementation

    func shouldShowWithdrawalAlert(for tokenItem: TokenItem) -> Bool {
        let objectRepresentable = Self.storedKey(for: tokenItem)
        let displayed = shownWithdrawalAlerts[objectRepresentable] ?? false
        shownWithdrawalAlerts[objectRepresentable] = true

        return !displayed
    }
}

private extension GeneralReceiveTokenWithdrawNoticeInteractor {
    static func storedKey(for tokenItem: TokenItem) -> String {
        Constants.keyPrefix + noticeKey(for: tokenItem)
    }

    enum Constants {
        static let keyPrefix = "receive_shown_withdrawal_"
    }

    enum StorageKeys: String, RawRepresentable {
        case shownWithdrawalAlerts = "receive_shown_withdrawal_token_alerts"
    }
}
