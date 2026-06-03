//
//  WalletConnectConnectedDAppPersistentDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain

struct WalletConnectConnectedDAppPersistentDTO: Codable {
    let sessionTopic: String
    let namespaces: [String: SessionNamespace]
    let identifier: Identifier
    let dAppName: String
    let dAppDomainURL: URL
    let dAppIconURL: URL?
    let verificationStatus: VerificationStatus
    let dAppBlockchains: [DAppBlockchain]
    let expiryDate: Date
    let connectionDate: Date
}

extension WalletConnectConnectedDAppPersistentDTO {
    enum VerificationStatus: Codable {
        case verified
        case unknownDomain
        case malicious
    }

    struct Identifier: Codable {
        let userWalletID: String
        let accountID: String
    }

    struct DAppBlockchain: Codable {
        let blockchain: Blockchain
        let isRequired: Bool
    }

    struct Account: Codable {
        let namespace: String
        let reference: String
        let address: String
    }

    struct SessionNamespace: Codable {
        let blockchains: Set<Blockchain>?
        let accounts: [Account]
        let methods: Set<String>
        let events: Set<String>
    }
}
