//
//  WalletConnectDAppConnectionViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@MainActor
enum WalletConnectDAppConnectionViewState {
    case connectionRequest(WalletConnectDAppConnectionRequestViewModel)
    case verifiedDomain(WalletConnectDAppDomainVerificationViewModel)
    case networkSelector(WalletConnectNetworksSelectorViewModel)
    case connectionTarget(AccountSelectorViewModel)
    case error(WalletConnectErrorViewModel)

    var connectionRequestState: WalletConnectDAppConnectionRequestViewState? {
        if case .connectionRequest(let viewModel) = self {
            return viewModel.state
        }

        return nil
    }
}

extension WalletConnectDAppConnectionViewState: @MainActor Equatable {
    static func == (lhs: WalletConnectDAppConnectionViewState, rhs: WalletConnectDAppConnectionViewState) -> Bool {
        switch (lhs, rhs) {
        case (.connectionRequest(let lhsViewModel), .connectionRequest(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        case (.verifiedDomain(let lhsViewModel), .verifiedDomain(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        case (.networkSelector(let lhsViewModel), .networkSelector(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        case (.connectionTarget(let lhsViewModel), .connectionTarget(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        case (.error(let lhsViewModel), .error(let rhsViewModel)):
            lhsViewModel === rhsViewModel

        default:
            false
        }
    }
}
