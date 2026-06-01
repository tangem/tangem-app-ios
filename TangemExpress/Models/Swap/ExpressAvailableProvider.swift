//
//  ExpressAvailableProvider.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

public class ExpressAvailableProvider {
    private let context: ExpressProviderFlowContext
    private let manager: ExpressProviderManager

    public var provider: ExpressProvider { context.provider }
    public var pair: ExpressManagerSwappingPair { context.pair }
    public var rateType: ExpressProviderRateType { context.rateType }
    public var expressFeeProvider: ExpressFeeProvider { context.expressFeeProvider }

    public var isBest: Bool { _isBest { $0 } }

    // MARK: - Updatable state

    private let _isBest = OSAllocatedUnfairLock<Bool>(initialState: false)

    init(context: ExpressProviderFlowContext, manager: ExpressProviderManager) {
        self.context = context
        self.manager = manager
    }

    deinit {
        ExpressLogger.debug(self, "deinit")
    }

    public func getState() -> ExpressProviderManagerState {
        manager.getState()
    }
}

// MARK: - Internal

extension ExpressAvailableProvider {
    func update(isBest: Bool) {
        _isBest { $0 = isBest }
    }

    func update(request: ExpressAvailableProviderUpdatingRequest) async {
        guard let request = makeRequest(request: request) else {
            ExpressLogger.info(self, "Skip updateState: amount is empty (nil or zero)")
            return
        }

        await manager.update(request: request)
    }

    func requestData(request: ExpressAvailableProviderUpdatingRequest) async throws -> ExpressTransactionData {
        guard let request = makeRequest(request: request) else {
            throw ExpressManagerError.amountNotFound
        }

        return try await manager.sendData(request: request)
    }

    func reset() {
        _isBest { $0 = false }

        manager.reset()
    }
}

// MARK: - Private

private extension ExpressAvailableProvider {
    func makeRequest(request: ExpressAvailableProviderUpdatingRequest) -> ExpressManagerSwappingPairRequest? {
        guard let amountType = request.amountType, amountType.amount > 0 else {
            return nil
        }

        return ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: request.approvePolicy,
            operationType: pair.source.operationType,
            quotesLoadingPerformanceTracker: request.quotesLoadingPerformanceTracker
        )
    }
}

// MARK: - Equatable

extension ExpressAvailableProvider: Equatable {
    public static func == (lhs: ExpressAvailableProvider, rhs: ExpressAvailableProvider) -> Bool {
        lhs === rhs
    }
}

// MARK: - CustomStringConvertible

extension ExpressAvailableProvider: CustomStringConvertible {
    public var description: String {
        objectDescription(self, userInfo: ["provider": provider.name])
    }
}

struct ExpressAvailableProviderUpdatingRequest {
    let amountType: ExpressAmountType?
    let approvePolicy: ApprovePolicy
    let quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?
}

// MARK: - [ExpressAvailableProvider]+

public extension Array where Element == ExpressAvailableProvider {
    func sortedByAttractively() -> [ExpressAvailableProvider] {
        sorted(by: ExpressProviderManagerComparator.isBetter)
    }

    func best() -> ExpressAvailableProvider? {
        self.min(by: ExpressProviderManagerComparator.isBetter)
    }

    func updateIsBestFlag() {
        let candidates = filter { provider in
            let state = provider.getState()
            switch state {
            case .error, .restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _):
                return false
            default:
                return state.quote != nil
            }
        }

        guard candidates.count > 1 else {
            forEach { $0.update(isBest: false) }
            return
        }

        let best = candidates.best()

        forEach { provider in
            provider.update(isBest: provider === best)
        }

        let providers = map(\.provider.name).joined(separator: ", ")
        ExpressLogger.info("Update providers \(providers). Best: \(best?.provider.name ?? "no best provider")")
    }

    func showableProviders() -> [ExpressAvailableProvider] {
        filter { $0.getState().isShowable }
    }

    func showableProviders(selectedProviderId: String?) -> [ExpressAvailableProvider] {
        filter { provider in
            // If the provider `isSelected` we are forced to show it anyway
            let isSelected = selectedProviderId == provider.provider.id
            let isAvailableToShow = provider.getState().isShowable

            return isSelected || isAvailableToShow
        }
    }
}
