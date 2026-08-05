//
//  SwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType?
    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState
}

extension SwapPairUpdateHandler {
    /// Resolves the source token's amount scale before the pair reaches `TangemExpress`, so that the module
    /// converts amounts without knowing where the scale comes from or having to reach the network for it.
    func makePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerSwappingPair {
        ExpressManagerSwappingPair(
            source: source,
            destination: destination,
            sourceAmountScale: try await source.scaledUIAmountMultiplierResolver?.resolve()
        )
    }
}
