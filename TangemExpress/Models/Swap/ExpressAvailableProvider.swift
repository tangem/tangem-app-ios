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
    public let rateType: ExpressProviderRateType

    public var provider: ExpressProvider { context.provider }
    public var pair: ExpressManagerSwappingPair { context.pair }
    public var expressFeeProvider: ExpressFeeProvider { context.expressFeeProvider }

    public var isBest: Bool { _isBest { $0 } }
    public var amount: Decimal? { _amount { $0 } }
    public var approvePolicy: ApprovePolicy { _approvePolicy { $0 } }

    // MARK: - Updatable state

    private let _isBest = OSAllocatedUnfairLock<Bool>(initialState: false)
    private let _amount = OSAllocatedUnfairLock<Decimal?>(initialState: nil)
    private let _approvePolicy = OSAllocatedUnfairLock<ApprovePolicy>(initialState: .specified)

    init(context: ExpressProviderFlowContext, manager: ExpressProviderManager, rateType: ExpressProviderRateType) {
        self.context = context
        self.manager = manager
        self.rateType = rateType
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

    func update(amount: Decimal, quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?) async {
        _amount { $0 = amount }

        await updateState(quotesLoadingPerformanceTracker: quotesLoadingPerformanceTracker)
    }

    func update(approvePolicy: ApprovePolicy) {
        _approvePolicy { $0 = approvePolicy }
    }

    func updateState(quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker? = nil) async {
        guard let request = makeRequest(quotesLoadingPerformanceTracker: quotesLoadingPerformanceTracker) else {
            ExpressLogger.info(self, "Skip updateState: amount is empty (nil or zero)")
            return
        }

        await manager.update(request: request)
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let request = makeRequest(quotesLoadingPerformanceTracker: nil) else {
            throw ExpressManagerError.amountNotFound
        }

        return try await manager.sendData(request: request)
    }

    func reset() {
        _amount { $0 = .none }
        _approvePolicy { $0 = .specified }

        manager.reset()
    }
}

// MARK: - Private

private extension ExpressAvailableProvider {
    func makeRequest(quotesLoadingPerformanceTracker: ExpressQuotesLoadingPerformanceTracker?) -> ExpressManagerSwappingPairRequest? {
        guard let amount, amount > 0 else {
            return nil
        }

        let amountType: ExpressAmountType = switch rateType {
        case .fixed: .to(amount)
        case .float: .from(amount)
        }

        return ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: approvePolicy,
            operationType: pair.source.operationType,
            quotesLoadingPerformanceTracker: quotesLoadingPerformanceTracker
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

// MARK: - [ExpressAvailableProvider]+

public extension Array where Element == ExpressAvailableProvider {
    func sortedByAttractively() -> [ExpressAvailableProvider] {
        sorted(by: ExpressProviderManagerComparator.isBetter)
    }

    func best() -> ExpressAvailableProvider? {
        self.min(by: ExpressProviderManagerComparator.isBetter)
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

    func updateIsBestFlag() {
        let candidates = filter { provider in
            switch provider.getState() {
            case .permissionRequired, .revokeAndPermissionRequired, .cexPreview, .dexPreview:
                return true
            case .idle, .error, .restriction:
                return false
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
}
