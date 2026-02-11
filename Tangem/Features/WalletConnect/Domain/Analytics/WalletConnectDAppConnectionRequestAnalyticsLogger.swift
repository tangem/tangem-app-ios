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

    /// `accountAnalyticsProviding`  should become non-optional when account migration is complete ([REDACTED_INFO])
    func logConnectionProposalReceived(
        _ connectionProposal: WalletConnectDAppConnectionProposal,
        accountAnalyticsProviding: (any AccountModelAnalyticsProviding)?
    )

    /// `accountAnalyticsProviding`  should become non-optional when account migration is complete ([REDACTED_INFO])
    func logConnectButtonTapped(dAppName: String, accountAnalyticsProviding: (any AccountModelAnalyticsProviding)?)
    func logCancelButtonTapped()

    func logDAppConnected(with dAppData: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus)
    func logDAppConnectionFailed(with error: WalletConnectDAppProposalApprovalError)
    func logDAppDisconnected(with dAppData: WalletConnectDAppData)
}
