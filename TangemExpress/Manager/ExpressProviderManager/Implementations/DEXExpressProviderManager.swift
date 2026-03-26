//
//  DEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class DEXExpressProviderManager {
    // MARK: - Dependencies

    private let helper: DEXProviderFlowHelper

    // MARK: - State

    private let swappingPair: ExpressManagerSwappingPair
    private let expressFeeProvider: ExpressFeeProvider
    private var _state: ThreadSafeContainer<ExpressProviderManagerState> = .init(.idle)

    init(
        provider: ExpressProvider,
        swappingPair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper
    ) {
        self.swappingPair = swappingPair
        self.expressFeeProvider = expressFeeProvider
        helper = DEXProviderFlowHelper(
            provider: provider,
            pair: swappingPair,
            expressFeeProvider: expressFeeProvider,
            expressAPIProvider: expressAPIProvider,
            mapper: mapper
        )
    }
}

// MARK: - ExpressProviderManager

extension DEXExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { swappingPair }
    var feeProvider: any ExpressFeeProvider { expressFeeProvider }

    func getState() -> ExpressProviderManagerState {
        _state.read()
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await helper.getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state.mutate { $0 = state }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        try helper.sendData(currentState: _state.read())
    }
}

// MARK: - CustomStringConvertible

extension DEXExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
