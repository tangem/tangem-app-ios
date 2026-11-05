//
//  PolymarketFastTradingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
@testable import Tangem

enum PolymarketSessionKeyFixtures {
    static let validity: TimeInterval = 180 * 24 * 60 * 60
    static let now = Date(timeIntervalSince1970: 1_789_430_400)
    static let hour: TimeInterval = 60 * 60
    static let day: TimeInterval = 24 * hour
    static let validUntil = now.addingTimeInterval(validity)
    static let deviceId = "this-device"
    static let deviceName = "iPhone"
    static let localAddress = "0x5e55000000000000000000000000000000000001"

    enum Owner {
        case local
        case previous
        case otherDevice

        var address: String {
            switch self {
            case .local: PolymarketSessionKeyFixtures.localAddress
            case .previous: "0x5e55000000000000000000000000000000000002"
            case .otherDevice: "0x5e55000000000000000000000000000000000003"
            }
        }

        var deviceId: String {
            switch self {
            case .local, .previous: PolymarketSessionKeyFixtures.deviceId
            case .otherDevice: "other-device"
            }
        }
    }

    static func key(
        _ owner: Owner = .local,
        status: PolymarketSessionKey.Status = .active,
        isEnabled: Bool = true,
        validUntil: Date? = PolymarketSessionKeyFixtures.validUntil,
        renewAfter: Date? = nil,
        authorizedAt: Date? = now.addingTimeInterval(-day),
        createdAt: Date? = nil
    ) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: owner.address,
            deviceId: owner.deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: ["CLOB"],
            validUntil: validUntil,
            renewAfter: renewAfter,
            authorizedAt: authorizedAt,
            createdAt: createdAt ?? authorizedAt
        )
    }

    static func assess(
        keys: [PolymarketSessionKey],
        signers: [PolymarketSessionSigner]? = [],
        localAddress: String? = PolymarketSessionKeyFixtures.localAddress,
        operations: [PolymarketFastTradingOperation] = []
    ) -> PolymarketFastTradingAssessment {
        PolymarketFastTradingAssessment(
            snapshot: PolymarketFastTradingSnapshot(
                sessionKeys: keys,
                localKeyAddress: localAddress,
                deviceId: deviceId,
                signers: signers,
                now: now,
                operations: operations
            )
        )
    }
}
