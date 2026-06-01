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

        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: StubExpressWallet(), destination: StubExpressWallet()),
            rateType: .float,
            expressFeeProvider: StubExpressFeeProvider(),
            expressAPIProvider: StubExpressAPIProvider(),
            mapper: ExpressManagerMapper()
        )

        let available = ExpressAvailableProvider(
            context: context,
            manager: StubExpressProviderManager()
        )
        available.update(isBest: isBest)
        return available
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
    func getState() -> ExpressProviderManagerState { .idle }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}

private struct StubExpressWallet: ExpressSourceWallet {
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
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee { fatalError("Not used in tests") }
}

private final class StubExpressAPIProvider: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { fatalError("Not used in tests") }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { fatalError("Not used in tests") }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { fatalError("Not used in tests") }
    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote { fatalError("Not used in tests") }
    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData { fatalError("Not used in tests") }
    func exchangeStatus(transactionId: String) async throws -> ExpressTransaction { fatalError("Not used in tests") }
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
    func exchangeHistory(walletAddress: String, cursor: Any?, limit: Int?, network: String?, tokenId: String?) async throws -> ExchangeHistoryPage { fatalError("Not used in tests") }
    func onrampHistory(walletAddress: String, cursor: Any?, limit: Int?, network: String?, tokenId: String?) async throws -> OnrampHistoryPage { fatalError("Not used in tests") }
}
