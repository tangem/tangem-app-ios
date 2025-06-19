//
//  WalletConnectDAppProposalApprovalError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Error that may occur during the approval or rejection of a dApp connection proposal.
enum WalletConnectDAppProposalApprovalError: Error {
    /// Indicates an issue in Tangem app connection request building logic.
    /// - Warning: If you received this error, your logic is probably bugged. See ``ReownWalletConnectDAppDataService``.
    case invalidConnectionRequest(any Error)

    /// The dApp connection proposal has expired.
    /// - Note: may occur if waiting time between loading proposal and connecting (approving) was more than 5 minutes.
    case proposalExpired

    /// An untyped error thrown during dApp connection proposal approval.
    case approvalFailed(any Error)

    /// An untyped error thrown during dApp connection proposal rejection.
    case rejectionFailed(any Error)

    /// The dApp connection proposal approval or rejection was explicitly cancelled by the user.
    case cancelledByUser
}
