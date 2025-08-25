//
//  WalletConnectErrorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import struct Foundation.URL

@MainActor
final class WalletConnectErrorViewModel {
    private let contactSupportAction: () -> Void
    private let closeAction: () -> Void

    let state: WalletConnectErrorViewState

    init(state: WalletConnectErrorViewState, contactSupportAction: @escaping () -> Void, closeAction: @escaping () -> Void) {
        self.state = state
        self.contactSupportAction = contactSupportAction
        self.closeAction = closeAction
    }
}

// MARK: - View events handling

extension WalletConnectErrorViewModel {
    func handle(viewEvent: WalletConnectErrorViewEvent) {
        switch viewEvent {
        case .closeButtonTapped:
            closeAction()

        case .contactSupportLinkTapped:
            contactSupportAction()

        case .buttonTapped:
            closeAction()
        }
    }
}
