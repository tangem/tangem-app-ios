//
//  PolymarketBatchSigning.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketBatchSigning {
    func sign(
        _ batch: PolymarketRelayedBatch.Unsigned,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketRelayedBatch
}

protocol PolymarketBatchesSigning {
    func sign(
        _ batches: [PolymarketRelayedBatch.Unsigned],
        ownerAuthTimestamp: String?,
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> PolymarketSignedBatches
}

extension PolymarketBatchesSigning {
    func sign(
        _ batches: [PolymarketRelayedBatch.Unsigned],
        as ownerAddress: String
    ) async throws(PolymarketSigningError) -> [PolymarketRelayedBatch] {
        try await sign(batches, ownerAuthTimestamp: nil, as: ownerAddress).batches
    }
}

struct PolymarketSignedBatches {
    let batches: [PolymarketRelayedBatch]
    let ownerAuthHeaders: PolymarketCLOBAuthHeaders?
}
