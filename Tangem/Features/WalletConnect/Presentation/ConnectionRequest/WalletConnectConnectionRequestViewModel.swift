//
//  WalletConnectConnectionRequestViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectConnectionRequestViewModel: ObservableObject {
    private let getDAppUseCase: WalletConnectGetDAppUseCase

    private var dAppLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectionRequestViewState

    init(state: WalletConnectConnectionRequestViewState, getDAppUseCase: WalletConnectGetDAppUseCase) {
        self.state = state
        self.getDAppUseCase = getDAppUseCase
    }

    deinit {
        dAppLoadingTask?.cancel()
    }
}

// MARK: - View events handling

extension WalletConnectConnectionRequestViewModel {
    func handle(viewEvent: WalletConnectConnectionRequestViewEvent) {
        switch viewEvent {
        case .viewDidAppear:
            handleViewDidAppear()

        case .verifiedDomainIconTapped:
            handleVerifiedDomainIconTapped()

        case .connectionRequestSectionHeaderTapped:
            handleConnectionRequestSectionHeaderTapped()

        case .walletRowTapped:
            handleWalletRowTapped()

        case .networksRowTapped:
            handleNetworksRowTapped()

        case .cancelButtonTapped:
            handleCancelButtonTapped()

        case .connectButtonTapped:
            handleConnectButtonTapped()
        }
    }

    private func handleViewDidAppear() {
        dAppLoadingTask?.cancel()

        dAppLoadingTask = Task { [weak self, getDAppUseCase] in
            do {
                let dApp = try await getDAppUseCase()
                // [REDACTED_TODO_COMMENT]
            } catch {
                // [REDACTED_TODO_COMMENT]
            }
        }
    }

    private func handleVerifiedDomainIconTapped() {}

    private func handleConnectionRequestSectionHeaderTapped() {}

    private func handleWalletRowTapped() {}

    private func handleNetworksRowTapped() {}

    private func handleCancelButtonTapped() {}

    private func handleConnectButtonTapped() {}
}
