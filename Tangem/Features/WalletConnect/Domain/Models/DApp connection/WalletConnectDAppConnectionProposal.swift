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
    let sessionProposal: WalletConnectSessionProposal

    let requiredBlockchains: Set<Blockchain>
    let optionalBlockchains: Set<Blockchain>?

    init(dApp: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus, sessionProposal: WalletConnectSessionProposal) {
        self.dApp = dApp
        self.verificationStatus = verificationStatus
        self.sessionProposal = sessionProposal

        requiredBlockchains = sessionProposal.requiredNamespaces.blockchainsSet

        optionalBlockchains = if let optionalNamespaces = sessionProposal.optionalNamespaces {
            optionalNamespaces.blockchainsSet
        } else {
            nil
        }
    }
}

private extension [String: WalletConnectSessionProposal.Namespace] {
    var blockchainsSet: Set<Blockchain> {
        Set(values.compactMap(\.blockchains).flatMap { $0 })
    }
}
