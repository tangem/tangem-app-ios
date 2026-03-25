//
//  TangemPayReceiveTokenWithdrawNoticeInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

class TangemPayReceiveTokenWithdrawNoticeInteractor: ReceiveTokenWithdrawNoticeInteractor {
    func shouldShowWithdrawalAlert(for tokenItem: TokenItem) -> Bool {
        true
    }

    func markWithdrawalAlertShown(for tokenItem: TokenItem) {}
}
