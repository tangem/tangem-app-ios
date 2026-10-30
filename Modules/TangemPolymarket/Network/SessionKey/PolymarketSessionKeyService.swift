//
//  PolymarketSessionKeyService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketSessionKeyService {
    func sessionKeys() async throws(PolymarketSessionKeyError) -> [PolymarketSessionKey]

    func authorize(_ authorization: PolymarketSessionKeyAuthorization) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey

    func revoke(_ revocation: PolymarketSessionKeyRevocation) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey

    func setEnabled(_ isEnabled: Bool, sessionKeyAddress: String) async throws(PolymarketSessionKeyError) -> PolymarketSessionKey
}
