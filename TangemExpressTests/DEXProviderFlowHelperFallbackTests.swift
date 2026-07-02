//
//  DEXProviderFlowHelperFallbackTests.swift
//  TangemExpressTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import TangemExpress

@Suite("DEXProviderFlowHelper — approve-with-swap fallback")
struct DEXProviderFlowHelperFallbackTests {
    // MARK: - Gas-override fallback (readyToApproveAndSwap)

    /// If the state-override gas estimate fails (non-cancellation), the flow logs the error and falls back to the legacy two-step approve (.permissionRequired) instead of breaking the swap.
    @Test("gas-override estimate failure falls back to legacy permissionRequired")
    func readyToApproveAndSwap_gasOverrideFails_fallsBackToLegacy() async throws {
        let analyticsLogger = AnalyticsLoggerSpy()
        let fallbackFee = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.001")!))
        let feeProvider = FeeProviderStub(
            combinedResult: .failure(StubError.estimateFailed),
            approveFee: fallbackFee
        )
        let sut = makeSUT(feeProvider: feeProvider, analyticsLogger: analyticsLogger)

        let state = try await sut.readyToApproveAndSwap(
            request: makeRequest(),
            quote: makeQuote(),
            data: makeData(),
            approveData: makeApproveData()
        )

        guard case .permissionRequired(let permission) = state else {
            Issue.record("Expected .permissionRequired (legacy fallback), got \(state)")
            return
        }
        #expect(permission.fee == fallbackFee)
        #expect(analyticsLogger.gasEstimationOverrideErrorCount == 1)
    }

    /// A cancellation during gas estimation must propagate as a cancellation, never be swallowed into a legacy fallback — otherwise a user-cancelled flow would silently downgrade.
    @Test("cancellation during gas estimate is rethrown, not turned into a fallback")
    func readyToApproveAndSwap_cancellation_rethrows() async {
        let analyticsLogger = AnalyticsLoggerSpy()
        let feeProvider = FeeProviderStub(
            combinedResult: .failure(CancellationError()),
            approveFee: Fee(Amount(with: .ethereum(testnet: false), value: 0))
        )
        let sut = makeSUT(feeProvider: feeProvider, analyticsLogger: analyticsLogger)

        do {
            _ = try await sut.readyToApproveAndSwap(
                request: makeRequest(),
                quote: makeQuote(),
                data: makeData(),
                approveData: makeApproveData()
            )
            Issue.record("Expected readyToApproveAndSwap to rethrow CancellationError")
        } catch is CancellationError {
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(analyticsLogger.gasEstimationOverrideErrorCount == 0)
    }

    /// When the state-override gas estimate succeeds, the approve-with-swap preview is built carrying the combined total and the split-out approve leg.
    @Test("successful gas estimate builds the approve-with-swap preview with the combined and approve fees")
    func readyToApproveAndSwap_gasEstimateSucceeds_buildsApproveWithSwapPreview() async throws {
        let combinedTotal = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.0025")!))
        let approveLeg = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.0005")!))
        let feeProvider = FeeProviderStub(
            combinedResult: .success(ApproveWithSwapFee(total: combinedTotal, approve: approveLeg)),
            approveFee: zeroFee()
        )
        let sut = makeSUT(feeProvider: feeProvider, analyticsLogger: AnalyticsLoggerSpy())

        let state = try await sut.readyToApproveAndSwap(
            request: makeRequest(),
            quote: makeQuote(),
            data: makeData(),
            approveData: makeApproveData()
        )

        guard case .dexWithApprovePreview(let preview) = state else {
            Issue.record("Expected .dexWithApprovePreview, got \(state)")
            return
        }
        #expect(preview.combinedFee == combinedTotal)
        #expect(preview.approveData.approveFee == approveLeg)
    }

    // MARK: - Allowance routing (checkRestriction)

    /// Flag ON + a resolvable owner address: a plain permissionRequired allowance enters the approve-with-swap flow.
    @Test("flag ON with owner present routes permissionRequired into approve-with-swap")
    func checkRestriction_flagOnOwnerPresent_choosesApproveWithSwap() async {
        let approveData = ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract")
        let sut = makeSUT(
            feeProvider: FeeProviderStub(combinedResult: .failure(StubError.notImplemented), approveFee: zeroFee()),
            analyticsLogger: AnalyticsLoggerSpy(),
            address: "0xOwner",
            allowanceProvider: AllowanceProviderStub(state: .permissionRequired(approveData))
        )

        let result = await sut.checkRestriction(sourceAmount: 1, request: makeRequest(), quote: makeQuote(allowanceContract: "0xSpender"))

        guard case .dexApproveFlowState(let data) = result else {
            Issue.record("Expected .dexApproveFlowState, got \(result)")
            return
        }
        #expect(data.owner == "0xOwner")
        #expect(data.approveTransactionData.spender == "0xSpender")
        guard case .approve = data.approvalFlow else {
            Issue.record("Expected .approve approval flow")
            return
        }
    }

    /// Flag ON but the owner address can't be resolved: the flow degrades to the legacy two-step approve instead of attempting approve-with-swap.
    @Test("flag ON with nil owner falls back to legacy permissionRequired")
    func checkRestriction_flagOnOwnerNil_fallsBackToLegacy() async {
        let approveData = ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract")
        let fallbackFee = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.001")!))
        let sut = makeSUT(
            feeProvider: FeeProviderStub(combinedResult: .failure(StubError.notImplemented), approveFee: fallbackFee),
            analyticsLogger: AnalyticsLoggerSpy(),
            address: nil,
            allowanceProvider: AllowanceProviderStub(state: .permissionRequired(approveData))
        )

        let result = await sut.checkRestriction(sourceAmount: 1, request: makeRequest(), quote: makeQuote(allowanceContract: "0xSpender"))

        guard case .terminalState(.some(.permissionRequired(let permission))) = result else {
            Issue.record("Expected legacy .permissionRequired, got \(result)")
            return
        }
        #expect(permission.fee == fallbackFee)
        #expect(permission.data.spender == "0xSpender")
    }

    /// Revoke-required tokens (USDT-style) always use the legacy revoke→approve flow, never approve-with-swap — even with the flag on and a resolvable owner.
    @Test("revoke-required allowance always falls back to legacy revokeAndPermissionRequired")
    func checkRestriction_revokeRequired_fallsBackToLegacy() async {
        let revoke = ApproveTransactionData(txData: Data([0x00]), spender: "0xSpender", toContractAddress: "0xContract")
        let approve = ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract")
        let revokeTotal = Fee(Amount(with: .ethereum(testnet: false), value: Decimal(string: "0.003")!))
        let feeProvider = FeeProviderStub(
            combinedResult: .failure(StubError.notImplemented),
            approveFee: zeroFee(),
            revokeAndApproveFee: RevokeAndApproveFee(unit: zeroFee(), total: revokeTotal)
        )
        let sut = makeSUT(
            feeProvider: feeProvider,
            analyticsLogger: AnalyticsLoggerSpy(),
            address: "0xOwner",
            allowanceProvider: AllowanceProviderStub(state: .revokeAndPermissionRequired(revoke: revoke, approve: approve))
        )

        let result = await sut.checkRestriction(sourceAmount: 1, request: makeRequest(), quote: makeQuote(allowanceContract: "0xSpender"))

        guard case .terminalState(.some(.revokeAndPermissionRequired(let permission))) = result else {
            Issue.record("Expected legacy .revokeAndPermissionRequired, got \(result)")
            return
        }
        #expect(permission.fee == revokeTotal)
    }
}

// MARK: - Helpers

private extension DEXProviderFlowHelperFallbackTests {
    func makeSUT(
        feeProvider: ExpressFeeProvider,
        analyticsLogger: AnalyticsLogger,
        address: String? = "0xOwner",
        allowanceProvider: AllowanceProvider? = nil
    ) -> DEXProviderFlowHelper {
        let source = SourceWalletStub(analyticsLogger: analyticsLogger, address: address, allowanceProvider: allowanceProvider)
        let pair = ExpressManagerSwappingPair(source: source, destination: DestinationWalletStub())
        let context = ExpressProviderFlowContext(
            provider: makeProvider(),
            pair: pair,
            rateType: .float,
            expressFeeProvider: feeProvider,
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags(isApproveWithSwapEnabled: true, isChooseBestDEXEnabled: false)
        )
        return DEXProviderFlowHelper(context: context)
    }

    func makeProvider() -> ExpressProvider {
        ExpressProvider(
            id: "test-provider",
            name: "Test",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }

    func makeRequest() -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: .from(1),
            rateType: .float,
            approvePolicy: .specified,
            operationType: .swap,
            quotesLoadingPerformanceTracker: nil
        )
    }

    func makeQuote(allowanceContract: String? = nil) -> ExpressQuote {
        ExpressQuote(fromAmount: .zero, expectAmount: .zero, allowanceContract: allowanceContract, quoteId: nil, txType: nil)
    }

    func makeData() -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "0xDestination",
            extraDestinationId: nil,
            txValue: .zero,
            txData: "0xabcdef",
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }

    func makeApproveData() -> DEXProviderFlowHelper.RestrictionCheckResult.ApproveData {
        DEXProviderFlowHelper.RestrictionCheckResult.ApproveData(
            provider: makeProvider(),
            approvePolicy: .specified,
            approveTransactionData: ApproveTransactionData(txData: Data([0xAB]), spender: "0xSpender", toContractAddress: "0xContract"),
            approvalFlow: .approve,
            owner: "0xOwner"
        )
    }

    func zeroFee() -> Fee {
        Fee(Amount(with: .ethereum(testnet: false), value: 0))
    }
}

// MARK: - Doubles

private final class AnalyticsLoggerSpy: AnalyticsLogger {
    private(set) var gasEstimationOverrideErrorCount = 0

    func bestProviderSelected(_ provider: ExpressAvailableProvider) {}
    func logGasEstimationOverrideError(_ error: Error) { gasEstimationOverrideErrorCount += 1 }
    func logAppError(_ error: Error, provider: ExpressProvider) {}
    func logExpressAPIError(_ error: ExpressAPIError, provider: ExpressProvider, paymentMethod: OnrampPaymentMethod) {}
}

private final class FeeProviderStub: ExpressFeeProvider {
    private let combinedResult: Result<ApproveWithSwapFee, Error>
    private let approveFee: BSDKFee
    private let revokeAndApproveFee: RevokeAndApproveFee

    init(
        combinedResult: Result<ApproveWithSwapFee, Error>,
        approveFee: BSDKFee,
        revokeAndApproveFee: RevokeAndApproveFee = RevokeAndApproveFee(
            unit: Fee(Amount(with: .ethereum(testnet: false), value: 0)),
            total: Fee(Amount(with: .ethereum(testnet: false), value: 0))
        )
    ) {
        self.combinedResult = combinedResult
        self.approveFee = approveFee
        self.revokeAndApproveFee = revokeAndApproveFee
    }

    func feeCurrency() -> ExpressWalletCurrency { makeCurrency() }
    func feeCurrencyBalance() throws -> Decimal { 1000 }
    func estimatedFee(amount: Decimal) async throws -> BSDKFee { throw StubError.notImplemented }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { throw StubError.notImplemented }
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee { approveFee }
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee { throw StubError.notImplemented }
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee { revokeAndApproveFee }

    func transactionFee(
        data: ExpressTransactionDataType,
        allowanceOverride: AllowanceOverride,
        approveData: BSDKApproveTransactionData
    ) async throws -> ApproveWithSwapFee {
        try combinedResult.get()
    }
}

private struct AllowanceProviderStub: AllowanceProvider {
    let state: AllowanceState

    func allowanceState(request: ExpressManagerSwappingPairRequest, contractAddress: String, spender: String) async throws -> AllowanceState {
        state
    }

    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData {
        ApproveTransactionData(txData: Data(), spender: spender, toContractAddress: "0xContract")
    }
}

private final class FeeProviderFactoryStub: ExpressFeeProviderFactory {
    func makeExpressFeeProvider() -> any ExpressFeeProvider {
        FeeProviderStub(
            combinedResult: .failure(StubError.notImplemented),
            approveFee: Fee(Amount(with: .ethereum(testnet: false), value: 0))
        )
    }
}

private struct BalanceProviderStub: BalanceProvider {
    func getBalance() throws -> Decimal { 1_000_000 }
    func getCoinBalance() throws -> Decimal { 1_000_000 }
}

private struct TransactionValidatorStub: ExpressProviderTransactionValidator {
    func validateTransactionSize(data: String) -> Bool { true }
}

private struct DestinationWalletStub: ExpressDestinationWallet {
    var currency: ExpressWalletCurrency { makeCurrency() }
    var coinCurrency: ExpressWalletCurrency { makeCurrency() }
    var address: String? { "0xDestinationAddress" }
    var extraId: String? { nil }
}

private final class SourceWalletStub: ExpressSourceWallet {
    let analyticsLogger: AnalyticsLogger
    private let _address: String?
    private let _allowanceProvider: AllowanceProvider?

    init(analyticsLogger: AnalyticsLogger, address: String?, allowanceProvider: AllowanceProvider?) {
        self.analyticsLogger = analyticsLogger
        _address = address
        _allowanceProvider = allowanceProvider
    }

    var currency: ExpressWalletCurrency { makeCurrency() }
    var coinCurrency: ExpressWalletCurrency { makeCurrency() }
    var address: String? { _address }
    var extraId: String? { nil }

    var walletInfo: ExpressWalletInfo { ExpressWalletInfo(id: "stub", refcode: nil) }
    var allowanceProvider: AllowanceProvider? { _allowanceProvider }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { nil }
    var balanceProvider: BalanceProvider { BalanceProviderStub() }
    var providerTransactionValidator: ExpressProviderTransactionValidator { TransactionValidatorStub() }
    var operationType: ExpressOperationType { .swap }
    var supportedProvidersFilter: SupportedProvidersFilter { .swap }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { FeeProviderFactoryStub() }
    var yieldContractAddress: String? { nil }

    func prepareForYieldModuleDEXSwap(provider: ExpressProvider) async throws {}

    func yieldModuleDEXSwapData(data: ExpressTransactionData, provider: ExpressProvider, spender: String) async throws -> ExpressTransactionData {
        throw StubError.notImplemented
    }
}

private final class ExpressAPIProviderStub: ExpressAPIProvider {
    func assets(currencies: Set<ExpressWalletCurrency>) async throws -> [ExpressAsset] { [] }
    func pairs(from: Set<ExpressWalletCurrency>, to: Set<ExpressWalletCurrency>) async throws -> [ExpressPair] { [] }
    func providers(branch: ExpressBranch) async throws -> [ExpressProvider] { [] }

    func exchangeQuote(item: ExpressSwappableQuoteItem) async throws -> ExpressQuote {
        ExpressQuote(fromAmount: .zero, expectAmount: .zero, allowanceContract: nil, quoteId: nil, txType: nil)
    }

    func exchangeData(item: ExpressSwappableDataItem) async throws -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: .zero,
            toAmount: .zero,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: .zero,
            txData: nil,
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }

    func exchangeStatus(transactionId: String) async throws -> ExchangeTransaction {
        throw StubError.notImplemented
    }

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
            toAmount: nil,
            countryCode: "",
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
            toAmount: nil,
            countryCode: "",
            externalTxId: nil,
            externalTxURL: nil
        ))
    }

    func onrampStatus(transactionId: String) async throws -> OnrampTransaction {
        throw StubError.notImplemented
    }

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

private enum StubError: Error {
    case notImplemented
    case estimateFailed
}

private func makeCurrency() -> ExpressWalletCurrency {
    ExpressWalletCurrency(contractAddress: "0xToken", network: "ethereum", decimalCount: 6, symbol: "USDC")
}
