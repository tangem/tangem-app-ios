//
//  CombinedExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// A provider manager for hybrid providers whose CEX/DEX flow type is determined
/// dynamically based on the `/exchange-quote` response.
///
/// Flow:
/// 1. Calls `/exchange-quote` with the original amount
/// 2. Uses `ExpressFlowTypeResolver` to determine CEX (`.send`) or DEX (`.swap`)
/// 3. Delegates post-quote processing to the appropriate helper
final class CombinedExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper
    private let flowTypeResolver: ExpressFlowTypeResolver

    private let cexHelper: CEXProviderFlowHelper
    private let dexHelper: DEXProviderFlowHelper

    // MARK: - State

    private let swappingPair: ExpressManagerSwappingPair
    private let expressFeeProvider: ExpressFeeProvider
    private var _state: ThreadSafeContainer<ExpressProviderManagerState> = .init(.idle)
    private var _resolvedFlowType: ThreadSafeContainer<ExpressTransactionType?> = .init(nil)

    init(
        provider: ExpressProvider,
        swappingPair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        flowTypeResolver: ExpressFlowTypeResolver = DefaultExpressFlowTypeResolver()
    ) {
        self.provider = provider
        self.swappingPair = swappingPair
        self.expressFeeProvider = expressFeeProvider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.flowTypeResolver = flowTypeResolver

        // Helpers use providerTypeOverride so that downstream mapper logic
        // (e.g., txValue decimal conversion) uses the resolved type, not the
        // provider's static type which may be "combined" or similar.
        cexHelper = CEXProviderFlowHelper(
            provider: provider,
            pair: swappingPair,
            expressFeeProvider: expressFeeProvider,
            expressAPIProvider: expressAPIProvider,
            mapper: mapper,
            providerTypeOverride: .cex
        )

        dexHelper = DEXProviderFlowHelper(
            provider: provider,
            pair: swappingPair,
            expressFeeProvider: expressFeeProvider,
            expressAPIProvider: expressAPIProvider,
            mapper: mapper,
            providerTypeOverride: .dex
        )
    }
}

// MARK: - ExpressProviderManager

extension CombinedExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { swappingPair }
    var feeProvider: any ExpressFeeProvider { expressFeeProvider }

    func getState() -> ExpressProviderManagerState {
        _state.read()
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        _resolvedFlowType.mutate { $0 = nil }

        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state.mutate { $0 = state }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        guard let flowType = _resolvedFlowType.read() else {
            throw ExpressProviderError.transactionDataNotFound
        }

        switch flowType {
        case .send:
            return try await cexHelper.sendData(currentState: _state.read(), request: request)
        case .swap:
            return try dexHelper.sendData(currentState: _state.read())
        }
    }
}

// MARK: - Private

private extension CombinedExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            // 1. Fetch quote with original amount to determine the flow type
            let item = mapper.makeExpressSwappableItem(
                pair: swappingPair,
                request: request,
                providerId: provider.id,
                providerType: provider.type
            )
            let quote = try await expressAPIProvider.exchangeQuote(item: item)
            try Task.checkCancellation()

            // 2. Resolve flow type
            let flowType = flowTypeResolver.resolveFlowType(quote: quote, provider: provider)

            // 3. Delegate to the appropriate helper
            let state: ExpressProviderManagerState
            switch flowType {
            case .send:
                state = await cexHelper.processAfterQuote(quote: quote, request: request)
            case .swap:
                state = await dexHelper.processAfterQuote(quote: quote, request: request)
            }

            // 4. Post-check: the helper may have re-quoted (e.g., CEX fee subtraction),
            //    and the new quote may indicate a different flow type.
            if let result = await checkFlowSwitch(state: state, initialFlowType: flowType, request: request) {
                _resolvedFlowType.mutate { $0 = result.flowType }
                return result.state
            }

            _resolvedFlowType.mutate { $0 = flowType }
            return state
        } catch let error as ExpressAPIError {
            return mapAPIError(error)
        } catch {
            return .error(error, quote: .none)
        }
    }

    struct FlowSwitchResult {
        let flowType: ExpressTransactionType
        let state: ExpressProviderManagerState
    }

    /// Re-resolves flow type from the helper's resulting state quote.
    /// Returns a result if the flow type changed, `nil` if no switch is needed.
    /// Only one switch per `update()` cycle — the switched-to helper runs without further checks.
    func checkFlowSwitch(
        state: ExpressProviderManagerState,
        initialFlowType: ExpressTransactionType,
        request: ExpressManagerSwappingPairRequest
    ) async -> FlowSwitchResult? {
        guard let quote = state.quote else { return nil }

        let newFlowType = flowTypeResolver.resolveFlowType(quote: quote, provider: provider)
        guard newFlowType != initialFlowType else { return nil }

        // Build adjusted request — only CEX→DEX needs fee-adjusted amount
        let adjustedRequest: ExpressManagerSwappingPairRequest
        if case .preview(let preview) = state, preview.subtractFee > 0 {
            let reducedAmount = request.amount - preview.subtractFee
            guard reducedAmount > 0 else {
                return FlowSwitchResult(
                    flowType: newFlowType,
                    state: .restriction(.insufficientBalance(request.amount), quote: quote)
                )
            }
            adjustedRequest = ExpressManagerSwappingPairRequest(
                amountType: .from(reducedAmount),
                feeOption: request.feeOption,
                approvePolicy: request.approvePolicy,
                operationType: request.operationType
            )
        } else {
            adjustedRequest = request
        }

        let newState: ExpressProviderManagerState
        switch newFlowType {
        case .send:
            newState = await cexHelper.processAfterQuote(quote: quote, request: adjustedRequest)
        case .swap:
            newState = await dexHelper.processAfterQuote(quote: quote, request: adjustedRequest)
        }

        return FlowSwitchResult(flowType: newFlowType, state: newState)
    }

    func mapAPIError(_ error: ExpressAPIError) -> ExpressProviderManagerState {
        guard let amount = error.value?.amount else {
            return .error(error, quote: .none)
        }

        switch error.errorCode {
        case .exchangeTooSmallAmountError:
            return .restriction(.tooSmallAmount(amount), quote: .none)
        case .exchangeTooBigAmountError:
            return .restriction(.tooBigAmount(amount), quote: .none)
        default:
            return .error(error, quote: .none)
        }
    }
}

// MARK: - CustomStringConvertible

extension CombinedExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
