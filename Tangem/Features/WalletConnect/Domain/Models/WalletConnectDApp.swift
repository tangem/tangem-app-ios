//
//  WalletConnectDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import struct ReownWalletKit.SessionNamespace
import enum BlockchainSdk.Blockchain

struct WalletConnectDApp {
    let data: DAppData
    let verificationStatus: VerificationStatus
}

struct WalletConnectDAppConnectionProposal {
    let dApp: WalletConnectDApp.DAppData
    let verificationStatus: WalletConnectDApp.VerificationStatus
    let requiredBlockchains: [Blockchain]
    let optionalBlockchains: [Blockchain]
}

// MARK: - DApp data

extension WalletConnectDApp {
    struct DAppData {
        let name: String
        let domain: URL
        let icon: URL?
    }
}

// MARK: - Verification status

extension WalletConnectDApp {
    enum VerificationStatus {
        case verified
        case unknownDomain
        case malicious([AttackType])
    }
}

extension WalletConnectDApp.VerificationStatus {
    enum AttackType {
        case signatureFarming
        case approvalFarming
        case setApprovalForAll
        case transferFarming
        case rawEtherTransfer
        case seaportFarming
        case blurFarming
        case permitFarming
        case other
    }
}

// MARK: - Connection request

extension WalletConnectDApp {
    struct ConnectionRequest {
        let proposalID: String
        let sessionNamespaces: [String: SessionNamespace]
    }
}
