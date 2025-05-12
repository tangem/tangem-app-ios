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

struct WalletConnectAsyncUIRequest<T> {
    let event: WalletConnectEvent
    let message: String
    var approveAction: () async throws -> T
    var rejectAction: () async throws -> T
}

protocol WalletConnectUIDelegate {
    func showScreen(with request: WalletConnectUIRequest)
    @MainActor
    func getResponseFromUser<Result>(with request: WalletConnectAsyncUIRequest<Result>) async -> (() async throws -> Result)
}

final class WalletConnectAlertUIDelegate: WalletConnectUIDelegate {
    private let appPresenter: AppPresenter = .shared
    private let queue: DispatchQueue = .init(label: "com.tangem.wc.alertUIDelegate", qos: .userInitiated)

    func showScreen(with request: WalletConnectUIRequest) {
        queue.async { [weak self] in
            let alert = WalletConnectUIBuilder.makeAlert(
                for: request.event,
                message: request.message,
                onAcceptAction: request.approveAction,
                onReject: request.rejectAction ?? {}
            )

            self?.appPresenter.show(alert)
        }
    }

    @MainActor
    func getResponseFromUser<Result>(with request: WalletConnectAsyncUIRequest<Result>) async -> (() async throws -> Result) {
        await withCheckedContinuation { [weak self] continuation in
            self?.queue.async { [presenter = self?.appPresenter] in
                let alert = WalletConnectUIBuilder.makeAlert(
                    for: request.event,
                    message: request.message,
                    onAcceptAction: {
                        continuation.resume(returning: request.approveAction)
                    },
                    onReject: {
                        continuation.resume(returning: request.rejectAction)
                    }
                )

                presenter?.show(alert)
            }
        }
    }
}
