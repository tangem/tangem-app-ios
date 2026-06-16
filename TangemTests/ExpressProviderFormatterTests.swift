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

    @Test("Best DEX rate badge is shown when the provider is the best DEX")
    func bestDexRateBadgeShownWhenIsBestDEX() {
        let provider = makeAvailableProvider(isBestDEX: true)
        let formatter = ExpressProviderFormatter()

        let badge = formatter.mapToBadge(availableProvider: provider, hasHighPriceImpactWarning: false)

        #expect(badge == .bestDexRate)
    }

    @Test("Best DEX rate badge takes priority over best rate on the same provider")
    func bestDexRateTakesPriorityOverBestRate() {
        let provider = makeAvailableProvider(isBest: true, isBestDEX: true)
        let formatter = ExpressProviderFormatter()

        let badge = formatter.mapToBadge(availableProvider: provider, hasHighPriceImpactWarning: false)

        #expect(badge == .bestDexRate)
    }

    @Test("Best DEX rate badge is hidden when there is a high price impact warning")
    func bestDexRateBadgeHiddenWithWarning() {
        let provider = makeAvailableProvider(isBestDEX: true)
        let formatter = ExpressProviderFormatter()

        let badge = formatter.mapToBadge(availableProvider: provider, hasHighPriceImpactWarning: true)

        #expect(badge == nil)
    }

    // MARK: - Helpers

    private func makeAvailableProvider(isBest: Bool = false, isBestDEX: Bool = false) -> ExpressAvailableProvider {
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

        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: StubExpressWallet(), destination: StubExpressWallet()),
            rateType: .float,
            expressFeeProvider: StubExpressFeeProvider(),
            expressAPIProvider: StubExpressAPIProvider(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isApproveWithSwapEnabled: false, isChooseBestDEXEnabled: false)
        )

        let available = ExpressAvailableProvider(
            context: context,
            manager: StubExpressProviderManager()
        )
        available.update(isBest: isBest)
        available.update(isBestDEX: isBestDEX)
        return available
    }
}

@Suite("ExpressAvailableProvider — best DEX selection & ordering")
struct ExpressAvailableProviderBestDEXTests {
    // MARK: - bestPreferringDEX

    @Test("Prefers the best eligible DEX even when a CEX has a higher rate")
    func prefersDEXOverHigherRateCEX() {
        let cexHigh = makeProvider(id: "cex-high", type: .cex, expectAmount: 100)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cexLow = makeProvider(id: "cex-low", type: .cex, expectAmount: 80)

        let best = [cexHigh, dex, cexLow].bestPreferringDEX()

        #expect(best === dex)
    }

    @Test("Picks the best-rate DEX among several DEX")
    func picksBestRateAmongDEX() {
        let dexLow = makeProvider(id: "dex-low", type: .dex, expectAmount: 70)
        let dexHigh = makeProvider(id: "dex-high", type: .dex, expectAmount: 95)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)

        let best = [dexLow, dexHigh, cex].bestPreferringDEX()

        #expect(best === dexHigh)
    }

    @Test("Falls back to the overall best rate when there is no DEX")
    func fallbackToBestWhenNoDEX() {
        let cexHigh = makeProvider(id: "cex-high", type: .cex, expectAmount: 100)
        let cexLow = makeProvider(id: "cex-low", type: .cex, expectAmount: 80)

        let best = [cexHigh, cexLow].bestPreferringDEX()

        #expect(best === cexHigh)
    }

    @Test("Falls back to CEX when the only DEX is not eligible")
    func fallbackWhenDEXIneligible() {
        let ineligibleDEX = makeIdleProvider(id: "dex", type: .dex)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)

        let best = [ineligibleDEX, cex].bestPreferringDEX()

        #expect(best === cex)
    }

    @Test("Treats a dex-bridge provider as a DEX")
    func dexBridgeIsTreatedAsDEX() {
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        let dexBridge = makeProvider(id: "dex-bridge", type: .dexBridge, expectAmount: 90)

        let best = [cex, dexBridge].bestPreferringDEX()

        #expect(best === dexBridge)
    }

    // MARK: - updateIsBestFlagPreferringDEX

    @Test("Marks isBest on the overall best and isBestDEX on the best DEX separately")
    func marksBothFlagsOnDifferentProviders() {
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)

        [cex, dex].updateIsBestFlagPreferringDEX()

        #expect(cex.isBest)
        #expect(!cex.isBestDEX)
        #expect(dex.isBestDEX)
        #expect(!dex.isBest)
    }

    @Test("When the best rate is itself a DEX, only isBest is set (no separate DEX badge)")
    func bestRateDEXGetsNoDexFlag() {
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 100)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 80)

        [dex, cex].updateIsBestFlagPreferringDEX()

        #expect(dex.isBest)
        #expect(!dex.isBestDEX)
        #expect(!cex.isBest)
        #expect(!cex.isBestDEX)
    }

    @Test("Clears both flags when there is a single eligible candidate")
    func clearsFlagsWithSingleCandidate() {
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        let ineligibleDEX = makeIdleProvider(id: "dex", type: .dex)

        [cex, ineligibleDEX].updateIsBestFlagPreferringDEX()

        #expect(!cex.isBest)
        #expect(!cex.isBestDEX)
        #expect(!ineligibleDEX.isBestDEX)
    }

    // MARK: - sortedByAttractivelyPreferringBestDEX

    @Test("Moves the best DEX to the front, keeping the rest by attractiveness")
    func movesBestDEXToFront() {
        let cexHigh = makeProvider(id: "cex-high", type: .cex, expectAmount: 100)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cexLow = makeProvider(id: "cex-low", type: .cex, expectAmount: 80)
        let providers = [cexHigh, dex, cexLow]
        providers.updateIsBestFlagPreferringDEX()

        let sorted = providers.sortedByAttractivelyPreferringBestDEX()

        #expect(sorted.map(\.provider.id) == ["dex", "cex-high", "cex-low"])
    }

    @Test("Without a best DEX, ordering matches sortedByAttractively")
    func matchesAttractiveWhenNoBestDEX() {
        let cexHigh = makeProvider(id: "cex-high", type: .cex, expectAmount: 100)
        let cexLow = makeProvider(id: "cex-low", type: .cex, expectAmount: 80)
        let providers = [cexLow, cexHigh]

        let preferring = providers.sortedByAttractivelyPreferringBestDEX().map(\.provider.id)
        let attractively = providers.sortedByAttractively().map(\.provider.id)

        #expect(preferring == attractively)
    }

    // MARK: - permission-required DEX exclusion

    @Test("bestPreferringDEX skips a permission-required DEX and picks the next ready DEX")
    func bestPreferringDEXSkipsPermissionRequiredDEX() {
        let permissionDEX = makePermissionRequiredProvider(id: "dex-approve", type: .dex, expectAmount: 100)
        let readyDEX = makeProvider(id: "dex-ready", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 95)

        let best = [permissionDEX, readyDEX, cex].bestPreferringDEX()

        #expect(best === readyDEX)
    }

    @Test("isBestDEX goes to the best ready DEX, not a higher-rate permission-required DEX")
    func bestDEXFlagSkipsPermissionRequiredDEX() {
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        let permissionDEX = makePermissionRequiredProvider(id: "dex-approve", type: .dex, expectAmount: 95)
        let readyDEX = makeProvider(id: "dex-ready", type: .dex, expectAmount: 90)

        [cex, permissionDEX, readyDEX].updateIsBestFlagPreferringDEX()

        #expect(cex.isBest)
        #expect(readyDEX.isBestDEX)
        #expect(!permissionDEX.isBestDEX)
        #expect(!permissionDEX.isBest)
    }

    // MARK: - Helpers

    private func makeProvider(id: String, type: ExpressProviderType, expectAmount: Decimal) -> ExpressAvailableProvider {
        let provider = expressProvider(id: id, type: type)
        let quote = ExpressQuote(fromAmount: 1, expectAmount: expectAmount, allowanceContract: nil, quoteId: nil, txType: nil)
        let fee = Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18))
        let state = ExpressProviderManagerState.cexPreview(.init(provider: provider, subtractFee: 0, quote: quote, fee: fee))
        return availableProvider(provider: provider, state: state)
    }

    private func makeIdleProvider(id: String, type: ExpressProviderType) -> ExpressAvailableProvider {
        let provider = expressProvider(id: id, type: type)
        return availableProvider(provider: provider, state: .idle)
    }

    private func makePermissionRequiredProvider(id: String, type: ExpressProviderType, expectAmount: Decimal) -> ExpressAvailableProvider {
        let provider = expressProvider(id: id, type: type)
        let quote = ExpressQuote(fromAmount: 1, expectAmount: expectAmount, allowanceContract: nil, quoteId: nil, txType: nil)
        let fee = Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18))
        let state = ExpressProviderManagerState.permissionRequired(.init(
            provider: provider,
            policy: .specified,
            data: ApproveTransactionData(txData: Data(), spender: "0xspender", toContractAddress: "0xcontract"),
            approvalFlow: .approve,
            fee: fee,
            quote: quote
        ))
        return availableProvider(provider: provider, state: state)
    }

    private func expressProvider(id: String, type: ExpressProviderType) -> ExpressProvider {
        ExpressProvider(
            id: id,
            name: id,
            type: type,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }

    private func availableProvider(provider: ExpressProvider, state: ExpressProviderManagerState) -> ExpressAvailableProvider {
        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: StubExpressWallet(), destination: StubExpressWallet()),
            rateType: .float,
            expressFeeProvider: StubExpressFeeProvider(),
            expressAPIProvider: StubExpressAPIProvider(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isApproveWithSwapEnabled: false, isChooseBestDEXEnabled: true)
        )

        return ExpressAvailableProvider(context: context, manager: StubExpressProviderManager(state: state))
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
    private let state: ExpressProviderManagerState

    init(state: ExpressProviderManagerState = .idle) {
        self.state = state
    }

    func getState() -> ExpressProviderManagerState { state }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}

private struct StubExpressWallet: ExpressSourceWallet {
    var walletInfo: ExpressWalletInfo { ExpressWalletInfo(id: "stub", refcode: nil) }
    var currency: ExpressWalletCurrency { fatalError("Not used in tests") }
    var coinCurrency: ExpressWalletCurrency { fatalError("Not used in tests") }
    var address: String? { nil }
    var extraId: String? { nil }

    var allowanceProvider: AllowanceProvider? { nil }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { nil }
    var balanceProvider: BalanceProvider { fatalError("Not used in tests") }
    var analyticsLogger: AnalyticsLogger { fatalError("Not used in tests") }
    var providerTransactionValidator: ExpressProviderTransactionValidator { fatalError("Not used in tests") }
    var operationType: ExpressOperationType { fatalError("Not used in tests") }
    var supportedProvidersFilter: SupportedProvidersFilter { fatalError("Not used in tests") }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { fatalError("Not used in tests") }
}

private struct StubExpressFeeProvider: ExpressFeeProvider {
    func feeCurrency() -> ExpressWalletCurrency { fatalError("Not used in tests") }
    func feeCurrencyBalance() throws -> Decimal { fatalError("Not used in tests") }
    func estimatedFee(amount: Decimal) async throws -> BSDKFee { fatalError("Not used in tests") }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType, allowanceOverride: AllowanceOverride, approveData: BSDKApproveTransactionData) async throws -> ApproveWithSwapFee { fatalError("Not used in tests") }
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee { fatalError("Not used in tests") }
}

private final class StubExpressAPIProvider: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { fatalError("Not used in tests") }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { fatalError("Not used in tests") }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { fatalError("Not used in tests") }
    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote { fatalError("Not used in tests") }
    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData { fatalError("Not used in tests") }
    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction { fatalError("Not used in tests") }
    func exchangeSent(result: ExpressTransactionSentResult) async throws { fatalError("Not used in tests") }
    func onrampCurrencies() async throws -> [OnrampFiatCurrency] { fatalError("Not used in tests") }
    func onrampCountries() async throws -> [OnrampCountry] { fatalError("Not used in tests") }
    func onrampCountryByIP() async throws -> OnrampCountry { fatalError("Not used in tests") }
    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] { fatalError("Not used in tests") }
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair] { fatalError("Not used in tests") }
    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote { fatalError("Not used in tests") }
    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData { fatalError("Not used in tests") }
    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult { fatalError("Not used in tests") }
    func onrampStatus(transactionId: String) async throws -> OnrampTransaction { fatalError("Not used in tests") }
    func exchangeHistory(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage { fatalError("Not used in tests") }
    func exchangeHistoryDelta(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage { fatalError("Not used in tests") }
    func onrampHistory(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage { fatalError("Not used in tests") }
    func onrampHistoryDelta(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage { fatalError("Not used in tests") }
}
