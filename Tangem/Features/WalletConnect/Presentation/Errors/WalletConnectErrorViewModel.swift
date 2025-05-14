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
final class WalletConnectErrorViewModel: ObservableObject {
    private let supportURL: URL
    private let openURLAction: (URL) -> Void
    private let closeAction: () -> Void

    @Published private(set) var state: WalletConnectErrorViewState

    init(state: WalletConnectErrorViewState, supportURL: URL, openURLAction: @escaping (URL) -> Void, closeAction: @escaping () -> Void) {
        self.state = state
        self.supportURL = supportURL
        self.openURLAction = openURLAction
        self.closeAction = closeAction
    }
}

// MARK: - View events handling

extension WalletConnectErrorViewModel {
    func handle(viewEvent: WalletConnectErrorViewEvent) {
        switch viewEvent {
        case .closeButtonTapped:
            closeAction()

        case .linkTapped(let url):
            handleLinkTapped(url)

        case .buttonTapped:
            closeAction()
        }
    }

    private func handleLinkTapped(_ url: URL) {
        guard url == supportURL else { return }
        openURLAction(url)
    }
}
