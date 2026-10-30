//
//  PolymarketMapper+SessionSigners.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PolymarketMapper {
    func mapSessionSigners(_ response: PolymarketDTO.SessionSignersResponse) -> [PolymarketSessionSigner] {
        (response.signers ?? []).map { signer in
            PolymarketSessionSigner(
                address: signer.address.lowercased(),
                scopes: signer.scopes ?? [],
                validUntil: signer.validUntil.map(Self.date)
            )
        }
    }
}
