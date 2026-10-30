//
//  PolymarketSessionKeyRequests.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketSessionKeyAuthorization: Hashable, Sendable {
    public let batch: PolymarketRelayedBatch
    public let sessionKeyAddress: String
    public let deviceId: String
    public let deviceName: String
    public let validUntil: Date
    public let replacesSessionKeyAddress: String?

    public init(
        batch: PolymarketRelayedBatch,
        sessionKeyAddress: String,
        deviceId: String,
        deviceName: String,
        validUntil: Date,
        replacesSessionKeyAddress: String? = nil
    ) {
        self.batch = batch
        self.sessionKeyAddress = sessionKeyAddress
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.validUntil = validUntil
        self.replacesSessionKeyAddress = replacesSessionKeyAddress
    }
}

public struct PolymarketSessionKeyRevocation: Hashable, Sendable {
    public let batch: PolymarketRelayedBatch
    public let sessionKeyAddress: String

    public init(batch: PolymarketRelayedBatch, sessionKeyAddress: String) {
        self.batch = batch
        self.sessionKeyAddress = sessionKeyAddress
    }
}
