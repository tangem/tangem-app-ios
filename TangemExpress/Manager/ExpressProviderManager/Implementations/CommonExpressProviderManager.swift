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

    private let _state = OSAllocatedUnfairLock<ExpressProviderManagerState>(initialState: .idle)

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
    func getState() -> ExpressProviderManagerState {
        _state { $0 }
    }

    func reset() {
        update(state: .idle)
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        ExpressLogger.info(self, "Start updating state with request - \(request)")
        let state = await getState(request: request)

        // A cancelled update must not write its result: this provider instance is shared across
        // update tasks, and a newer (winning) request may have already stored a fresh quote here.
        guard !Task.isCancelled else {
            ExpressLogger.info(self, "Skip applying state: the update task was cancelled")
            return
        }

        update(state: state)
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let state = _state { $0 }

        switch state {
        case .cexPreview:
            let data = try await cexHelper.sendData(currentState: state, request: request)
            try ensureMatchingTxType(expected: .send, actual: data.transactionType)
            return data

        case .dexPreview, .dexWithApprovePreview:
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
    func update(state: ExpressProviderManagerState) {
        ExpressLogger.info(self, "Update state to \(state)")
        _state { $0 = state }
    }

    /// Fetches a quote, resolves the flow type, and delegates to the appropriate helper.
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            let quote = try await fetchQuote(request: request)
            request.quotesLoadingPerformanceTracker?.fulfill(hasError: false)

            try Task.checkCancellation()
            let flowType = flowTypeResolver.resolveFlowType(quote: quote, provider: context.provider)

            let state: ExpressProviderManagerState = switch flowType {
            case .send: await cexHelper.processAfterQuote(quote: quote, request: request)
            case .swap: await dexHelper.processAfterQuote(quote: quote, request: request)
            }

            return state

        } catch let error as ExpressAPIError {
            request.quotesLoadingPerformanceTracker?.fulfill(hasError: true)
            let currencySymbol = context.pair.currencySymbol(for: request.amountType)
            return .mapError(error, currencySymbol: currencySymbol)
        } catch let error as CancellationError {
            // Don't fulfill again here: if cancellation fires after `fetchQuote`, the success
            // fulfill above has already run. Otherwise the trace closes on tracker `deinit`.
            return .error(error, quote: .none)
        } catch {
            request.quotesLoadingPerformanceTracker?.fulfill(hasError: true)
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
        objectDescription(self, userInfo: ["provider": context.provider.name])
    }
}
