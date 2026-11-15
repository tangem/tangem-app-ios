//
//  PolymarketSessionKeyRequests.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketSessionKeyRequestError: Error, Equatable {
    case callMissingFromBatch
}

public struct PolymarketSessionKeyAuthorization: Hashable, Sendable {
    public let batch: PolymarketRelayedBatch
    public let grant: PolymarketSessionKeyGrant
    public let deviceId: String
    public let deviceName: String
    public let replacesSessionKeyAddress: String?

    public init(
        batch: PolymarketRelayedBatch,
        grant: PolymarketSessionKeyGrant,
        deviceId: String,
        deviceName: String,
        replacesSessionKeyAddress: String? = nil
    ) throws(PolymarketSessionKeyRequestError) {
        guard batch.calls.contains(grant.call) else {
            throw .callMissingFromBatch
        }

        self.batch = batch
        self.grant = grant
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.replacesSessionKeyAddress = replacesSessionKeyAddress
    }
}

public struct PolymarketSessionKeyRevocation: Hashable, Sendable {
    public let batch: PolymarketRelayedBatch
    public let sessionKeyAddress: String

    public init(batch: PolymarketRelayedBatch, sessionKeyAddress: String) throws(PolymarketSessionKeyRequestError) {
        let call = try? PolymarketSessionKeyCalls.revoke(
            sessionKeyAddress: sessionKeyAddress,
            depositWalletAddress: batch.depositWalletAddress
        )

        guard let call, batch.calls.contains(call) else {
            throw .callMissingFromBatch
        }

        self.batch = batch
        self.sessionKeyAddress = sessionKeyAddress
    }
}
