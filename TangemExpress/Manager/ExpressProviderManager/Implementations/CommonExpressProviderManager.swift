//
//  CommonExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Unified provider manager that determines CEX/DEX flow type dynamically
/// based on the `/exchange-quote` response.
///
/// Flow:
/// 1. Calls `/exchange-quote` with the original amount
/// 2. Uses `ExpressFlowTypeResolver` to determine CEX (`.send`) or DEX (`.swap`)
/// 3. Delegates post-quote processing to the appropriate helper
final class CommonExpressProviderManager {
    // MARK: - Dependencies

    private let context: ExpressProviderFlowContext
    private let flowTypeResolver: ExpressFlowTypeResolver

    private let cexHelper: CEXProviderFlowHelper
    private let dexHelper: DEXProviderFlowHelper

    // MARK: - State

    private var _state: ThreadSafeContainer<ExpressProviderManagerState> = .init(.idle)

    init(
        context: ExpressProviderFlowContext,
        flowTypeResolver: ExpressFlowTypeResolver
    ) {
        self.context = context
        self.flowTypeResolver = flowTypeResolver

        cexHelper = CEXProviderFlowHelper(context: context)
        dexHelper = DEXProviderFlowHelper(context: context)
    }
}

// MARK: - ExpressProviderManager

extension CommonExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { context.pair }
    var feeProvider: any ExpressFeeProvider { context.expressFeeProvider }

    func getState() -> ExpressProviderManagerState {
        _state.read()
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state.mutate { $0 = state }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let state = _state.read()

        switch state {
        case .cexPreview:
            let data = try await cexHelper.sendData(currentState: state, request: request)
            try ensureMatchingTxType(expected: .send, actual: data.transactionType)
            return data

        case .dexPreview:
            let data = try dexHelper.sendData(currentState: state)
            try ensureMatchingTxType(expected: .swap, actual: data.transactionType)
            return data

        case .idle, .error, .restriction, .permissionRequired, .revokeAndPermissionRequired:
            throw ExpressProviderError.transactionDataNotFound
        }
    }
}

// MARK: - Private

private extension CommonExpressProviderManager {
    /// Fetches a quote, resolves the flow type, and delegates to the appropriate helper.
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            let quote = try await fetchQuote(request: request)
            let flowType = flowTypeResolver.resolveFlowType(quote: quote, provider: context.provider)

            switch flowType {
            case .send:
                return await cexHelper.processAfterQuote(quote: quote, request: request)
            case .swap:
                return await dexHelper.processAfterQuote(quote: quote, request: request)
            }
        } catch let error as ExpressAPIError {
            let currencySymbol = context.pair.currencySymbol(for: request.amountType)
            return .mapError(error, currencySymbol: currencySymbol)
        } catch {
            return .error(error, quote: .none)
        }
    }

    func fetchQuote(request: ExpressManagerSwappingPairRequest) async throws -> ExpressQuote {
        let item = context.mapper.makeExpressSwappableItem(
            pair: context.pair,
            request: request,
            providerId: context.provider.id,
            providerType: context.provider.type
        )
        let quote = try await context.expressAPIProvider.exchangeQuote(item: item)
        try Task.checkCancellation()
        return quote
    }

    /// A `txType` mismatch between `/exchange-quote` and `/exchange-data` violates the API
    /// contract — the user has approved a flow that no longer matches the data they would sign.
    /// Per S089: stop and surface an error rather than silently switching flows.
    func ensureMatchingTxType(expected: ExpressTransactionType, actual: ExpressTransactionType) throws {
        guard expected != actual else { return }
        ExpressLogger.warning(self, "txType mismatch: quote=\(expected), data=\(actual)")
        throw ExpressProviderError.transactionTypeMismatch
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
