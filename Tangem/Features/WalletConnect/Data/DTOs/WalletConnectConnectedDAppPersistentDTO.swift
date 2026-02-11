//
//  WalletConnectConnectedDAppPersistentDTO.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import enum BlockchainSdk.Blockchain

struct WalletConnectConnectedDAppPersistentDTOV1: Codable {
    let sessionTopic: String
    let namespaces: [String: WalletConnectConnectedDAppPersistentDTO.SessionNamespace]
    let userWalletID: WalletConnectConnectedDAppPersistentDTO.IdentifierV1
    let dAppName: String
    let dAppDomainURL: URL
    let dAppIconURL: URL?
    let verificationStatus: WalletConnectConnectedDAppPersistentDTO.VerificationStatus
    let dAppBlockchains: [WalletConnectConnectedDAppPersistentDTO.DAppBlockchain]
    let expiryDate: Date
    let connectionDate: Date
}

struct WalletConnectConnectedDAppPersistentDTOV2: Codable {
    let sessionTopic: String
    let namespaces: [String: WalletConnectConnectedDAppPersistentDTO.SessionNamespace]
    let identifier: WalletConnectConnectedDAppPersistentDTO.IdentifierV2
    let dAppName: String
    let dAppDomainURL: URL
    let dAppIconURL: URL?
    let verificationStatus: WalletConnectConnectedDAppPersistentDTO.VerificationStatus
    let dAppBlockchains: [WalletConnectConnectedDAppPersistentDTO.DAppBlockchain]
    let expiryDate: Date
    let connectionDate: Date
}

enum WalletConnectConnectedDAppPersistentDTO {
    case v1(WalletConnectConnectedDAppPersistentDTOV1)
    case v2(WalletConnectConnectedDAppPersistentDTOV2)

    var sessionTopic: String {
        switch self {
        case .v1(let dto): return dto.sessionTopic
        case .v2(let dto): return dto.sessionTopic
        }
    }

    var namespaces: [String: SessionNamespace] {
        switch self {
        case .v1(let dto): return dto.namespaces
        case .v2(let dto): return dto.namespaces
        }
    }

    var dAppName: String {
        switch self {
        case .v1(let dto): return dto.dAppName
        case .v2(let dto): return dto.dAppName
        }
    }

    var dAppDomainURL: URL {
        switch self {
        case .v1(let dto): return dto.dAppDomainURL
        case .v2(let dto): return dto.dAppDomainURL
        }
    }

    var dAppIconURL: URL? {
        switch self {
        case .v1(let dto): return dto.dAppIconURL
        case .v2(let dto): return dto.dAppIconURL
        }
    }

    var verificationStatus: VerificationStatus {
        switch self {
        case .v1(let dto): return dto.verificationStatus
        case .v2(let dto): return dto.verificationStatus
        }
    }

    var dAppBlockchains: [DAppBlockchain] {
        switch self {
        case .v1(let dto): return dto.dAppBlockchains
        case .v2(let dto): return dto.dAppBlockchains
        }
    }

    var expiryDate: Date {
        switch self {
        case .v1(let dto): return dto.expiryDate
        case .v2(let dto): return dto.expiryDate
        }
    }

    var connectionDate: Date {
        switch self {
        case .v1(let dto): return dto.connectionDate
        case .v2(let dto): return dto.connectionDate
        }
    }
}

extension WalletConnectConnectedDAppPersistentDTO {
    enum VerificationStatus: Codable {
        case verified
        case unknownDomain
        case malicious
    }

    typealias IdentifierV1 = String

    struct IdentifierV2: Codable {
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

extension WalletConnectConnectedDAppPersistentDTO: Codable {
    init(from decoder: Decoder) throws {
        if let v2 = try? WalletConnectConnectedDAppPersistentDTOV2(from: decoder) {
            self = .v2(v2)
            return
        }

        if let v1 = try? WalletConnectConnectedDAppPersistentDTOV1(from: decoder) {
            self = .v1(v1)
            return
        }

        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported WalletConnectConnectedDAppPersistentDTO payload"))
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .v1(let dto):
            try dto.encode(to: encoder)
        case .v2(let dto):
            try dto.encode(to: encoder)
        }
    }
}
