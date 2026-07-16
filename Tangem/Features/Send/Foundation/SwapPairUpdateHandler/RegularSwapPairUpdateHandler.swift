//
//  RegularSwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Pair update handler for the regular swap flow.
/// No estimation on first selection. Always uses float (`.from`) direction.
final class RegularSwapPairUpdateHandler: SwapPairUpdateHandler {
    private let expressManager: ExpressManager
    private let swapRepository: SwapRepository
    private let analyticsLogger: SwapManagementModelAnalyticsLogger

    init(
        expressManager: ExpressManager,
        swapRepository: SwapRepository,
        analyticsLogger: SwapManagementModelAnalyticsLogger
    ) {
        self.expressManager = expressManager
        self.swapRepository = swapRepository
        self.analyticsLogger = analyticsLogger
    }

    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        guard let source, let destination else {
            return nil
        }

        let pair = ExpressManagerSwappingPair(source: source, destination: destination)

        // No loading for pair with the transfer type
        if pair.isTransfer {
            return nil
        }

        // Always update only providers. Not reload rates
        return .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        let pair = ExpressManagerSwappingPair(source: source, destination: destination)

        if pair.isTransfer {
            analyticsLogger.logSwapTransferModeSwitched()
        }

        if !pair.isTransfer {
            let cachedPairs = await swapRepository.getPairs(from: source.currency)
            let isPairCached = cachedPairs.contains { $0.destination == destination.currency.asCurrency }

            if !isPairCached {
                try await swapRepository.updatePairs(for: source.currency, userWalletInfo: source.userWalletInfo)
            }
        }

        // In regular swap we clear the cached amount type when the pair changes.
        // Use try? to ignore errors from previous failed provider loading - new update(pair:) will retry
        let _ = try? await expressManager.update(amountType: .none)

        return try await expressManager.update(pair: pair)
    }
}
