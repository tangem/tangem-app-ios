//
//  PolymarketSessionKey.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSessionKey: Hashable, Sendable {
    public let address: String
    public let deviceId: String?
    public let deviceName: String?
    public let isEnabled: Bool
    public let status: Status
    public let scopes: [String]
    public let validUntil: Date?
    public let authorizedAt: Date?
    public let createdAt: Date?

    public init(
        address: String,
        deviceId: String?,
        deviceName: String?,
        isEnabled: Bool,
        status: Status,
        scopes: [String],
        validUntil: Date?,
        authorizedAt: Date?,
        createdAt: Date?
    ) {
        self.address = address
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.isEnabled = isEnabled
        self.status = status
        self.scopes = scopes
        self.validUntil = validUntil
        self.authorizedAt = authorizedAt
        self.createdAt = createdAt
    }
}

public extension PolymarketSessionKey {
    enum Status: Hashable, Sendable {
        case pending
        case active
        case revoking
        case revoked
        case expired
        case failed
        case unknown(String)

        public init(apiValue: String) {
            switch apiValue.uppercased() {
            case "PENDING": self = .pending
            case "ACTIVE": self = .active
            case "REVOKING": self = .revoking
            case "REVOKED": self = .revoked
            case "EXPIRED": self = .expired
            case "FAILED": self = .failed
            default: self = .unknown(apiValue)
            }
        }

        public var isSettling: Bool {
            switch self {
            case .pending, .revoking: true
            case .active, .revoked, .expired, .failed, .unknown: false
            }
        }
    }
}
