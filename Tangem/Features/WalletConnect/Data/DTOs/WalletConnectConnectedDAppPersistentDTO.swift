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
    let userWalletID: String
    let dAppName: String
    let dAppDomainURL: URL
    let dAppIconURL: URL?
    let verificationStatus: VerificationStatus
    let blockchains: [Blockchain]
    let expiryDate: Date
    let connectionDate: Date
}

extension WalletConnectConnectedDAppPersistentDTO {
    enum VerificationStatus: Codable {
        case verified
        case unknownDomain
        case malicious
    }
}
