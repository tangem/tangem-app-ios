//
//  ExpressProviderFormatterTests.swift
//  TangemTests
//
//  Created on 03.04.2026.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress
@testable import BlockchainSdk

@Suite("ExpressProviderFormatter — mapToBadge badge suppression", .serialized)
struct ExpressProviderFormatterBadgeTests {
    init() {
        InjectedValues[\.ukGeoDefiner] = StubUKGeoDefiner()
    }

    @Test("Best rate badge is shown when there is no high price impact warning")
    func bestRateBadgeShownWithoutWarning() {
        let provider = makeAvailableProvider(isBest: true)
        let formatter = ExpressProviderFormatter()

        let badge = formatter.mapToBadge(availableProvider: provider, hasHighPriceImpactWarning: false)

        #expect(badge == .bestRate)
    }

    @Test("Best rate badge is hidden when there is a high price impact warning")
    func bestRateBadgeHiddenWithWarning() {
        let provider = makeAvailableProvider(isBest: true)
        let formatter = ExpressProviderFormatter()

        let badge = formatter.mapToBadge(availableProvider: provider, hasHighPriceImpactWarning: true)

        #expect(badge == nil)
    }

    // MARK: - Helpers

    private func makeAvailableProvider(isBest: Bool) -> ExpressAvailableProvider {
        let provider = ExpressProvider(
            id: "test-provider",
            name: "Test Provider",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )

        let manager = StubExpressProviderManager()

        return ExpressAvailableProvider(
            provider: provider,
            manager: manager,
            supportedRateTypes: [.float],
            isBest: isBest
        )
    }
}

// MARK: - Stubs

private struct StubUKGeoDefiner: UKGeoDefiner {
    var isUK: Bool { false }

    func initialize() {}
    func waitForGeoIpRegionIfNeeded() async {}
}

private final class StubExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair {
        fatalError("Not used in tests")
    }

    var feeProvider: ExpressFeeProvider {
        fatalError("Not used in tests")
    }

    func getState() -> ExpressProviderManagerState {
        .idle
    }

    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}
