//
//  WalletConnectDAppConnectionRequestAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

protocol WalletConnectDAppConnectionRequestAnalyticsLogger {
    func logSessionInitiated()
    func logSessionFailed(with error: WalletConnectDAppProposalLoadingError)

    func logConnectionProposalReceived(_ connectionProposal: WalletConnectDAppConnectionProposal)

    func logConnectButtonTapped()
    func logCancelButtonTapped()

    func logDAppConnected(with dAppData: WalletConnectDAppData)
    func logDAppConnectionFailed(with error: WalletConnectDAppProposalApprovalError)
    func logDAppDisconnected(with dAppData: WalletConnectDAppData)
}
