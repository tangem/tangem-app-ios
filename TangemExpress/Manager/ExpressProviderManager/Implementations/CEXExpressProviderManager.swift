//
//  CEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CEXExpressProviderManager {
    // MARK: - Dependencies

    private let helper: CEXProviderFlowHelper

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
        helper = CEXProviderFlowHelper(
            provider: provider,
            pair: swappingPair,
            expressFeeProvider: expressFeeProvider,
            expressAPIProvider: expressAPIProvider,
            mapper: mapper
        )
    }
}

// MARK: - ExpressProviderManager

extension CEXExpressProviderManager: ExpressProviderManager {
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
        try await helper.sendData(currentState: _state.read(), request: request)
    }
}

// MARK: - CustomStringConvertible

extension CEXExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
