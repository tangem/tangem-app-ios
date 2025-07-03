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
    case solanaBlockchainWarning(WalletConnectSolanaBlockchainWarningViewModel)
    case walletSelector(WalletConnectWalletSelectorViewModel)
    case networkSelector(WalletConnectNetworksSelectorViewModel)
    case error(WalletConnectErrorViewModel)
}
