//
//  WalletConnectUIDelegate.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectUIRequest {
    let event: WalletConnectEvent
    let message: String
    var approveAction: () -> Void
    var rejectAction: (() -> Void)?
}

protocol WalletConnectUIDelegate {
    func showScreen(with request: WalletConnectUIRequest)
}

struct WalletConnectAlertUIDelegate: WalletConnectUIDelegate {
    private let appPresenter: AppPresenter = .shared

    func showScreen(with request: WalletConnectUIRequest) {
        let alert = WalletConnectUIBuilder.makeAlert(
            for: request.event,
            message: request.message,
            onAcceptAction: request.approveAction,
            onReject: request.rejectAction ?? {}
        )

        appPresenter.show(alert)
    }
}
