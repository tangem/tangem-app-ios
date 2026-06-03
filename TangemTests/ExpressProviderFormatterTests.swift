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
        InjectedValues[\.geoEligibilityService] = StubGeoEligibilityService()
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

@Suite("ExpressProviderFormatter — rate subtitle ordering", .serialized)
struct ExpressProviderFormatterRateSubtitleTests {
    @Test("ETH → USDT preserves source-is-base ordering: ETH on the left, USDT on the right")
    func ethToUsdt_sourceIsBase() {
        let formatter = ExpressProviderFormatter(isStablecoinOrderingEnabled: true)
        let eth = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
        let usdt = TokenItem.token(
            .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6, id: "tether"),
            .init(.ethereum(testnet: false), derivationPath: nil)
        )

        let subtitle = formatter.mapToRateSubtitle(
            fromAmount: 1,
            toAmount: 3000,
            senderTokenItem: eth,
            destinationTokenItem: usdt,
            option: .exchangeRate
        )

        try? expectRateOrdering(subtitle, baseSymbol: "ETH", quoteSymbol: "USDT")
    }

    @Test("USDT → ETH flips ordering so ETH is the base, USDT is the quote")
    func usdtToEth_receiveIsBase() {
        let formatter = ExpressProviderFormatter(isStablecoinOrderingEnabled: true)
        let eth = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
        let usdt = TokenItem.token(
            .init(name: "USDT", symbol: "USDT", contractAddress: "0xUSDT", decimalCount: 6, id: "tether"),
            .init(.ethereum(testnet: false), derivationPath: nil)
        )

        // Sending 3000 USDT → receiving 1 ETH
        let subtitle = formatter.mapToRateSubtitle(
            fromAmount: 3000,
            toAmount: 1,
            senderTokenItem: usdt,
            destinationTokenItem: eth,
            option: .exchangeRate
        )

        try? expectRateOrdering(subtitle, baseSymbol: "ETH", quoteSymbol: "USDT")
    }

    // MARK: - Helpers

    private func expectRateOrdering(_ subtitle: ProviderRowViewModel.Subtitle, baseSymbol: String, quoteSymbol: String) throws {
        guard case .text(let text) = subtitle else {
            Issue.record("Expected .text subtitle")
            return
        }

        guard
            let baseRange = text.range(of: baseSymbol),
            let quoteRange = text.range(of: quoteSymbol),
            let separatorRange = text.range(of: "≈")
        else {
            Issue.record("Subtitle '\(text)' missing one of: \(baseSymbol), \(quoteSymbol), ≈")
            return
        }

        #expect(baseRange.lowerBound < separatorRange.lowerBound, "\(baseSymbol) must appear before ≈ in '\(text)'")
        #expect(quoteRange.lowerBound > separatorRange.upperBound, "\(quoteSymbol) must appear after ≈ in '\(text)'")
    }
}

// MARK: - Stubs

private struct StubGeoEligibilityService: GeoEligibilityService {
    var isUK: Bool { false }
    var isApplePayAllowed: Bool { true }

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
