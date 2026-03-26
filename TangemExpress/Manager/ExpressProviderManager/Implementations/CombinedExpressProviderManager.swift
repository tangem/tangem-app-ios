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
            _resolvedFlowType.mutate { $0 = flowType }

            // 3. Delegate to the appropriate helper
            switch flowType {
            case .send:
                return await cexHelper.processAfterQuote(quote: quote, request: request)
            case .swap:
                return await dexHelper.processAfterQuote(quote: quote, request: request)
            }
        } catch let error as ExpressAPIError {
            return mapAPIError(error)
        } catch {
            return .error(error, quote: .none)
        }
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
