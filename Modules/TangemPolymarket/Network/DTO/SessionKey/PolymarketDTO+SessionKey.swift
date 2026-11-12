//
//  PolymarketDTO+SessionKey.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketDTO {
    struct SessionKey: Decodable {
        let address: String
        let deviceId: String?
        let deviceName: String?
        let enabled: Bool?
        let status: String
        let scopes: [String]?
        let validUntil: Int?
        let authorizedAt: Int?
        let createdAt: Int?
    }

    struct SessionKeyAuthorizationRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let sessionKeyAddress: String
        let deviceId: String
        let deviceName: String
        let validUntil: String
        let nonce: String
        let deadline: String
        let calls: [RelayedCall]
        let signature: String
        let replacesSessionKeyAddress: String?

        init(
            batch: PolymarketRelayedBatch,
            sessionKeyAddress: String,
            deviceId: String,
            deviceName: String,
            validUntil: String,
            replacesSessionKeyAddress: String?
        ) {
            ownerAddress = batch.ownerAddress
            depositWalletAddress = batch.depositWalletAddress
            self.sessionKeyAddress = sessionKeyAddress
            self.deviceId = deviceId
            self.deviceName = deviceName
            self.validUntil = validUntil
            nonce = batch.nonce
            deadline = batch.deadline
            calls = batch.calls.map(RelayedCall.init)
            signature = batch.signature
            self.replacesSessionKeyAddress = replacesSessionKeyAddress
        }
    }

    struct SessionKeyRevocationRequest: Encodable {
        let ownerAddress: String
        let depositWalletAddress: String
        let sessionKeyAddress: String
        let nonce: String
        let deadline: String
        let calls: [RelayedCall]
        let signature: String

        init(batch: PolymarketRelayedBatch, sessionKeyAddress: String) {
            ownerAddress = batch.ownerAddress
            depositWalletAddress = batch.depositWalletAddress
            self.sessionKeyAddress = sessionKeyAddress
            nonce = batch.nonce
            deadline = batch.deadline
            calls = batch.calls.map(RelayedCall.init)
            signature = batch.signature
        }
    }

    struct SessionKeyEnabledRequest: Encodable {
        let enabled: Bool
    }
}
