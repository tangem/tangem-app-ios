//
//  CEXProviderFlowHelperFeeShortfallTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import TangemExpress

@Suite("CEXProviderFlowHelper — fee shortfall classification")
struct CEXProviderFlowHelperFeeShortfallTests {
    /// Gasless: the fee is paid in the source token and the balance can't cover amount + fee. The blocker is the
    /// fee, so the `.to` flow must surface `.gaslessFeeShortfall` ("Not Enough Fee"), not `.insufficientBalance`
    /// ("Not Enough Funds"). Regression for [REDACTED_INFO].
    @Test("to-flow: gasless fee that can't be covered maps to a gasless fee shortfall")
    func toFlow_gaslessFeeUncoverable_mapsToFeeShortfall() async {
        let sut = makeSUT(
            feeCurrency: tokenCurrency,
            sourceCurrency: tokenCurrency,
            sourceBalance: 1,
            feeCurrencyBalance: 1,
            estimatedFee: tokenFee(value: 5),
            isGaslessFeeSelected: true
        )

        let state = await sut.processAfterQuote(quote: makeQuote(fromAmount: 1), request: makeRequest(.to(1)))

        guard case .restriction(.gaslessFeeShortfall, _) = state else {
            Issue.record("Expected .gaslessFeeShortfall, got \(state)")
            return
        }
    }

    /// Gasless via the `.from` flow: the fee is larger than the amount being swapped, so it can't be subtracted.
    /// Must also map to a gasless fee shortfall rather than insufficient funds.
    @Test("from-flow: gasless fee larger than amount maps to a gasless fee shortfall")
    func fromFlow_gaslessFeeExceedsAmount_mapsToFeeShortfall() async {
        let sut = makeSUT(
            feeCurrency: tokenCurrency,
            sourceCurrency: tokenCurrency,
            sourceBalance: 3,
            feeCurrencyBalance: 3,
            estimatedFee: tokenFee(value: 5),
            isGaslessFeeSelected: true
        )

        let state = await sut.processAfterQuote(quote: makeQuote(fromAmount: 1), request: makeRequest(.from(1)))

        guard case .restriction(.gaslessFeeShortfall, _) = state else {
            Issue.record("Expected .gaslessFeeShortfall, got \(state)")
            return
        }
    }

    /// A genuine coin-source swap pays the fee in the native coin (not gasless). When it can't cover amount + fee
    /// that really is an insufficient-funds situation, so the `.insufficientBalance` restriction must be preserved.
    @Test("to-flow: non-gasless fee that can't be covered stays an insufficient-balance restriction")
    func toFlow_nonGaslessFeeUncoverable_staysInsufficientBalance() async {
        let sut = makeSUT(
            feeCurrency: coinCurrency,
            sourceCurrency: coinCurrency,
            sourceBalance: 1,
            feeCurrencyBalance: 1,
            estimatedFee: coinFee(value: 5),
            isGaslessFeeSelected: false
        )

        let state = await sut.processAfterQuote(quote: makeQuote(fromAmount: 1), request: makeRequest(.to(1)))

        guard case .restriction(.insufficientBalance(let required), _) = state else {
            Issue.record("Expected .insufficientBalance, got \(state)")
            return
        }
        #expect(required == 1)
    }
}

// MARK: - Fixtures & SUT

private extension CEXProviderFlowHelperFeeShortfallTests {
    var tokenCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0xUSDC", network: "polygon", decimalCount: 6, symbol: "USDC")
    }

    var coinCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "", network: "polygon", decimalCount: 18, symbol: "POL")
    }

    func tokenFee(value: Decimal) -> BSDKFee {
        let token = Token(name: "USD Coin", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6)
        return Fee(Amount(with: token, value: value))
    }

    func coinFee(value: Decimal) -> BSDKFee {
        Fee(Amount(with: .polygon(testnet: false), value: value))
    }

    func makeSUT(
        feeCurrency: ExpressWalletCurrency,
        sourceCurrency: ExpressWalletCurrency,
        sourceBalance: Decimal,
        feeCurrencyBalance: Decimal,
        estimatedFee: BSDKFee,
        isGaslessFeeSelected: Bool
    ) -> CEXProviderFlowHelper {
        let feeProvider = CEXFeeProviderStub(
            currency: feeCurrency,
            balance: feeCurrencyBalance,
            fee: estimatedFee,
            isGaslessFeeSelected: isGaslessFeeSelected
        )
        let source = SourceWalletStub(currency: sourceCurrency, balance: sourceBalance)
        let pair = ExpressManagerSwappingPair(source: source, destination: DestinationWalletStub())
        let context = ExpressProviderFlowContext(
            provider: makeProvider(),
            pair: pair,
            rateType: .float,
            expressFeeProvider: feeProvider,
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isApproveWithSwapEnabled: false, isChooseBestDEXEnabled: false)
        )
        return CEXProviderFlowHelper(context: context)
    }

    func makeProvider() -> ExpressProvider {
        ExpressProvider(
            id: "test-provider",
            name: "Test",
            type: .cex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }

    func makeRequest(_ amountType: ExpressAmountType) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: .float,
            approvePolicy: .specified,
            operationType: .swap,
            quotesLoadingPerformanceTracker: nil
        )
    }

    func makeQuote(fromAmount: Decimal) -> ExpressQuote {
        ExpressQuote(fromAmount: fromAmount, expectAmount: fromAmount, allowanceContract: nil, quoteId: nil, txType: nil)
    }
}

// MARK: - Doubles

private struct CEXFeeProviderStub: ExpressFeeProvider {
    let currency: ExpressWalletCurrency
    let balance: Decimal
    let fee: BSDKFee
    let isGaslessFeeSelected: Bool

    func feeCurrency() -> ExpressWalletCurrency { currency }
    func feeCurrencyBalance() throws -> Decimal { balance }
    func estimatedFee(amount: Decimal) async throws -> BSDKFee { fee }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { fee }
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee { throw StubError.notImplemented }
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee { throw StubError.notImplemented }
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee {
        throw StubError.notImplemented
    }
}

private struct BalanceProviderStub: BalanceProvider {
    let balance: Decimal
    func getBalance() throws -> Decimal { balance }
    func getCoinBalance() throws -> Decimal { balance }
}

private struct TransactionValidatorStub: ExpressProviderTransactionValidator {
    func validateTransactionSize(data: String) -> Bool { true }
}

private final class AnalyticsLoggerStub: AnalyticsLogger {
    func bestProviderSelected(_ provider: ExpressAvailableProvider) {}
    func logGasEstimationOverrideError(_ error: Error) {}
    func logAppError(_ error: Error, provider: ExpressProvider) {}
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}
}

private final class FeeProviderFactoryStub: ExpressFeeProviderFactory {
    func makeExpressFeeProvider() -> any ExpressFeeProvider {
        CEXFeeProviderStub(
            currency: ExpressWalletCurrency(contractAddress: "", network: "polygon", decimalCount: 18, symbol: "POL"),
            balance: 0,
            fee: Fee(Amount(with: .polygon(testnet: false), value: 0)),
            isGaslessFeeSelected: false
        )
    }
}

private struct DestinationWalletStub: ExpressDestinationWallet {
    var currency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "0xNasdaq", network: "solana", decimalCount: 6, symbol: "NASDAQ")
    }

    var coinCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "", network: "solana", decimalCount: 9, symbol: "SOL")
    }

    var address: String? { "SolanaDestinationAddress" }
    var extraId: String? { nil }
}

private final class SourceWalletStub: ExpressSourceWallet {
    private let _currency: ExpressWalletCurrency
    private let _balance: Decimal

    init(currency: ExpressWalletCurrency, balance: Decimal) {
        _currency = currency
        _balance = balance
    }

    var currency: ExpressWalletCurrency { _currency }
    var coinCurrency: ExpressWalletCurrency {
        ExpressWalletCurrency(contractAddress: "", network: "polygon", decimalCount: 18, symbol: "POL")
    }

    var address: String? { "0xSourceAddress" }
    var extraId: String? { nil }

    var walletInfo: ExpressWalletInfo { ExpressWalletInfo(id: "stub", refcode: nil) }
    var allowanceProvider: AllowanceProvider? { nil }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { nil }
    var balanceProvider: BalanceProvider { BalanceProviderStub(balance: _balance) }
    var analyticsLogger: AnalyticsLogger { AnalyticsLoggerStub() }
    var providerTransactionValidator: ExpressProviderTransactionValidator { TransactionValidatorStub() }
    var operationType: ExpressOperationType { .swap }
    var supportedProvidersFilter: SupportedProvidersFilter { .cex }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { FeeProviderFactoryStub() }
}

private enum StubError: Error {
    case notImplemented
}

private final class ExpressAPIProviderStub: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { [] }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { [] }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { [] }

    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote {
        ExpressQuote(fromAmount: .zero, expectAmount: .zero, allowanceContract: nil, quoteId: nil, txType: nil)
    }

    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData {
        throw StubError.notImplemented
    }

    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction { throw StubError.notImplemented }
    func exchangeSent(result: ExpressTransactionSentResult) async throws {}

    func onrampCurrencies() async throws -> [OnrampFiatCurrency] { [] }
    func onrampCountries() async throws -> [OnrampCountry] { [] }

    func onrampCountryByIP() async throws -> OnrampCountry {
        let currency = OnrampFiatCurrency(identity: OnrampIdentity(name: "", code: "", image: nil), precision: 0)
        return OnrampCountry(identity: currency.identity, currency: currency, onrampAvailable: false)
    }

    func onrampPaymentMethods() async throws -> [OnrampPaymentMethod] { [] }
    func onrampPairs(from: OnrampFiatCurrency, to: [ExpressWalletCurrency], country: OnrampCountry) async throws -> [OnrampPair] { [] }

    func onrampQuote(item: OnrampQuotesRequestItem) async throws -> OnrampQuote {
        OnrampQuote(expectedAmount: .zero, nativePaymentAvailable: false, quoteId: nil)
    }

    func onrampData(item: OnrampRedirectDataRequestItem) async throws -> OnrampRedirectData {
        OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            externalTxId: nil,
            externalTxURL: nil
        )
    }

    func onrampNativePaymentData(item: OnrampNativePaymentRequestItem) async throws -> OnrampDataResult {
        .widget(OnrampRedirectData(
            txId: "",
            widgetURL: URL(string: "https://stub")!,
            redirectURL: URL(string: "https://stub")!,
            fromAmount: .zero,
            fromCurrencyCode: "",
            externalTxId: nil,
            externalTxURL: nil
        ))
    }

    func onrampStatus(transactionId: String) async throws -> OnrampTransaction { throw StubError.notImplemented }

    func exchangeHistory(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func exchangeHistoryDelta(item: ExpressHistoryRequestItem) async throws -> ExchangeHistoryPage {
        ExchangeHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistory(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }

    func onrampHistoryDelta(item: ExpressHistoryRequestItem) async throws -> OnrampHistoryPage {
        OnrampHistoryPage(records: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false)
    }
}
