//
//  TangemPayJoinWaitlistResponse.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayJoinWaitlistResponse: Decodable {
    public let status: Status
    public let joinedAt: Date?

    public init(status: Status, joinedAt: Date?) {
        self.status = status
        self.joinedAt = joinedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawStatus = try container.decodeIfPresent(String.self, forKey: .status)
        status = rawStatus.flatMap(Status.init(rawValue:)) ?? .joined
        joinedAt = try? container.decodeIfPresent(Date.self, forKey: .joinedAt)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case joinedAt
    }
}

// MARK: - Status

public extension TangemPayJoinWaitlistResponse {
    enum Status: String {
        case joined = "JOINED"
        case alreadyJoined = "ALREADY_JOINED"
    }
}
