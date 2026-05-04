//
//  WalletConnectDAppConnectionViewState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppConnectionViewState {
    case connectionRequest(WalletConnectDAppConnectionRequestViewModel)
    case verifiedDomain(WalletConnectDAppDomainVerificationViewModel)
    case networkSelector(WalletConnectNetworksSelectorViewModel)
    case connectionTarget(AccountSelectorViewModel)
    case error(WalletConnectErrorViewModel)
}
