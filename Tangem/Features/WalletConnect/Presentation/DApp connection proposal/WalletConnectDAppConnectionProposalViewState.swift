//
//  WalletConnectDAppConnectionProposalViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppConnectionProposalViewState: Equatable {
    case connectionRequest(WalletConnectDAppConnectionRequestViewModel)
    case verifiedDomain
    case walletSelector
    case networkSelector

    static func == (lhs: WalletConnectDAppConnectionProposalViewState, rhs: WalletConnectDAppConnectionProposalViewState) -> Bool {
        switch (lhs, rhs) {
        case (.connectionRequest, .connectionRequest):
            true
        case (.verifiedDomain, verifiedDomain):
            true
        case (.walletSelector, .walletSelector):
            true
        case (.networkSelector, .networkSelector):
            true
        default:
            false
        }
    }
}
