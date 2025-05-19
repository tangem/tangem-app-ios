//
//  WalletConnectConnectionRequestViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectConnectionRequestViewState {
    case details(WalletConnectConnectionRequestDetailsViewState)
    case verifiedDomain
    case walletSelector
    case networkSelector
}
