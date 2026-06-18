//
//  SendWithSwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Pair update handler for the send-via-swap flow.
final class SendWithSwapPairUpdateHandler: SwapPairUpdateHandler {
    private let expressManager: ExpressManager

    init(expressManager: ExpressManager) {
        self.expressManager = expressManager
    }

    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        let currentPair = await expressManager.getCurrentPair()
        let shouldReloadProviders = {
            guard let currentPair else {
                return true
            }

            guard currentPair.source.currency == source?.tokenItem.expressCurrency else {
                return true
            }

            guard currentPair.destination.currency == destination?.tokenItem.expressCurrency else {
                return true
            }

            return false
        }()

        let amountType = await expressManager.getAmountType()
        let hasAmount = amountType != nil

        if shouldReloadProviders {
            return hasAmount ? .rates : .providers
        }

        return .autoupdate
    }

    func updatePair(source: any SendSwapableToken, destination: any SendReceiveToken) async throws -> ExpressManagerState {
        let pair = ExpressManagerSwappingPair(source: source, destination: destination)
        let pairResult = try await expressManager.update(pair: pair)

        guard let amountType = await expressManager.getAmountType() else {
            return pairResult
        }

        return try await expressManager.update(amountType: amountType)
    }
}
