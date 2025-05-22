//
//  WalletConnectDAppConnectionProposalViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppConnectionProposalViewState {
    case connectionRequest(WalletConnectConnectionRequestViewModel)
    case verifiedDomain
    case walletSelector
    case networkSelector
}
