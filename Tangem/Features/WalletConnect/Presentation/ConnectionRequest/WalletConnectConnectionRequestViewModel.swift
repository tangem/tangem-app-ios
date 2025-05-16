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
    private let uri: WalletConnectV2URI
    private let analyticsSource: Analytics.WalletConnectSessionSource

    private var dAppInformationLoadingTask: Task<Void, Never>?

    @Published private(set) var state: WalletConnectConnectionRequestViewState

    init(state: WalletConnectConnectionRequestViewState, uri: WalletConnectV2URI, analyticsSource: Analytics.WalletConnectSessionSource) {
        self.state = state
        self.uri = uri
        self.analyticsSource = analyticsSource
    }

    deinit {
        dAppInformationLoadingTask?.cancel()
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
        dAppInformationLoadingTask?.cancel()

        dAppInformationLoadingTask = Task { [weak self] in

        }
    }

    private func handleVerifiedDomainIconTapped() {

    }

    private func handleConnectionRequestSectionHeaderTapped() {

    }

    private func handleWalletRowTapped() {

    }

    private func handleNetworksRowTapped() {

    }

    private func handleCancelButtonTapped() {

    }

    private func handleConnectButtonTapped() {

    }
}
