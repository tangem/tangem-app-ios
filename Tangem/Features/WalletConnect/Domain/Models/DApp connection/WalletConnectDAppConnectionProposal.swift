//
//  WalletConnectDAppConnectionProposal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum BlockchainSdk.Blockchain

struct WalletConnectDAppConnectionProposal {
    let dApp: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let sessionProposal: WalletConnectDAppSessionProposal

    init(dApp: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus, sessionProposal: WalletConnectDAppSessionProposal) {
        self.dApp = dApp
        self.verificationStatus = verificationStatus
        self.sessionProposal = sessionProposal
    }
}
