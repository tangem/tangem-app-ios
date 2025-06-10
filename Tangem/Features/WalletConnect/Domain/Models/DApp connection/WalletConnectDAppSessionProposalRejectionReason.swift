//
//  WalletConnectDAppSessionProposalRejectionReason.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppSessionProposalRejectionReason {
    /// dApp connection proposal was rejected explicitly by user.
    case userInitiated

    /// dApp domain is not supported by Tangem app.
    case unsupportedDAppDomain

    /// dApp has required blockchains that are not supported by Tangem app.
    case unsupportedBlockchains
}
