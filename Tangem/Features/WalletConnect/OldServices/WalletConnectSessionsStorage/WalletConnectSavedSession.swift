//
//  WalletConnectSavedSession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import struct Foundation.Date
import enum BlockchainSdk.Blockchain

struct WalletConnectSavedSession: Encodable, Hashable, Identifiable {
    var id: Int { hashValue }
    let userWalletId: String
    let connectionDate: Date?
    let connectedBlockchains: [Blockchain]
    let topic: String
    let sessionInfo: SessionInfo
}

// MARK: - Nested types

extension WalletConnectSavedSession {
    struct SessionInfo: Codable, Hashable {
        let dAppInfo: DAppInfo
    }

    struct DAppInfo: Codable, Hashable {
        let name: String
        let description: String
        let url: String
        let iconLinks: [String]
    }
}

// MARK: - Decodable

extension WalletConnectSavedSession: Decodable {
    private enum CodingKeys: String, CodingKey {
        case userWalletId
        case connectionDate
        case connectedBlockchains
        case topic
        case sessionInfo
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userWalletId = try container.decode(String.self, forKey: .userWalletId)
        connectionDate = try container.decodeIfPresent(Date.self, forKey: .connectionDate)
        connectedBlockchains = try container.decodeIfPresent([Blockchain].self, forKey: .connectedBlockchains) ?? []
        topic = try container.decode(String.self, forKey: .topic)
        sessionInfo = try container.decode(SessionInfo.self, forKey: .sessionInfo)
    }
}
