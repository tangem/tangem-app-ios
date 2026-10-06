//
//  ExpressAvailableProviderSlippageTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import TangemExpress

@Suite("ExpressAvailableProvider — custom slippage")
struct ExpressAvailableProviderSlippageTests {
    @Test("A custom slippage reaches only a provider that supports it", arguments: [true, false])
    func customSlippageIsGatedByProviderSupport(isCustomSlippageSupported: Bool) async {
        let manager = ExpressProviderManagerSpy()
        let sut = ExpressAvailableProvider(context: makeContext(isCustomSlippageSupported: isCustomSlippageSupported), manager: manager)

        await sut.update(request: ExpressAvailableProviderUpdatingRequest(
            amountType: .from(1),
            approvePolicy: .specified,
            slippage: Decimal(string: "0.01"),
            quotesLoadingPerformanceTracker: nil
        ))

        #expect(manager.requests.map(\.slippage) == [isCustomSlippageSupported ? Decimal(string: "0.01") : nil])
    }
}

// MARK: - Helpers

private extension ExpressAvailableProviderSlippageTests {
    func makeContext(isCustomSlippageSupported: Bool) -> ExpressProviderFlowContext {
        let source = SourceWalletStub(analyticsLogger: AnalyticsLoggerSpy(), address: "0xOwner", allowanceProvider: nil)
        let provider = ExpressProvider(
            id: "test-provider",
            name: "Test",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil,
            isCustomSlippageSupported: isCustomSlippageSupported
        )

        return ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: source, destination: DestinationWalletStub()),
            rateType: .float,
            expressFeeProvider: FeeProviderStub(
                combinedResult: .failure(StubError.estimateFailed),
                approveFee: Fee(Amount(with: .ethereum(testnet: false), value: 0))
            ),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isRegionRestrictionsEnabled: false)
        )
    }
}

// MARK: - Doubles

final class ExpressProviderManagerSpy: ExpressProviderManager {
    var requests: [ExpressManagerSwappingPairRequest] { _requests.withLock { $0 } }

    private let _requests = OSAllocatedUnfairLock(initialState: [ExpressManagerSwappingPairRequest]())

    func getState() -> ExpressProviderManagerState { .idle }
    func reset() {}

    func update(request: ExpressManagerSwappingPairRequest) async {
        _requests.withLock { $0.append(request) }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        throw StubError.estimateFailed
    }
}
