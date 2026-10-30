//
//  PolymarketMapper+SessionKey.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketMapper {
    func mapSessionKey(_ dto: PolymarketDTO.SessionKey) -> PolymarketSessionKey {
        PolymarketSessionKey(
            address: dto.address.lowercased(),
            deviceId: dto.deviceId,
            deviceName: dto.deviceName,
            isEnabled: dto.enabled ?? false,
            status: PolymarketSessionKey.Status(apiValue: dto.status),
            scopes: dto.scopes ?? [],
            validUntil: dto.validUntil.map(Self.date),
            renewAfter: dto.renewAfter.map(Self.date),
            authorizedAt: dto.authorizedAt.map(Self.date),
            createdAt: dto.createdAt.map(Self.date)
        )
    }
}

extension PolymarketMapper {
    static func date(_ seconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}
