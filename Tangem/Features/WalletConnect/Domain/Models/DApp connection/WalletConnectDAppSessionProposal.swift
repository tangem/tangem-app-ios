//
//  WalletConnectDAppSessionProposal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import enum BlockchainSdk.Blockchain

struct WalletConnectDAppSessionProposal {
    let id: String
    let requiredBlockchains: Set<Blockchain>
    let optionalBlockchains: Set<Blockchain>
    let initialVerificationContext: VerificationContext?

    let dAppWalletConnectionRequestFactory: (
        _ selectedBlockchains: [Blockchain],
        _ selectedUserWallet: any UserWalletModel
    ) throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppConnectionRequest

    let dAppAccountConnectionRequestFactory: (
        _ selectedBlockchains: [Blockchain],
        _ selectedAccount: any CryptoAccountModel,
        _ wcAccountsWalletModelProvider: any WalletConnectAccountsWalletModelProvider
    ) throws(WalletConnectDAppProposalApprovalError) -> WalletConnectDAppConnectionRequest
}

extension WalletConnectDAppSessionProposal {
    struct VerificationContext {
        let origin: URL?
        let validationStatus: ValidationStatus?
    }
}

extension WalletConnectDAppSessionProposal.VerificationContext {
    enum ValidationStatus {
        case valid
        case invalid
    }
}
