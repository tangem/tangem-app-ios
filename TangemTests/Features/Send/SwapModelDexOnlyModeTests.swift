//
//  SwapModelDexOnlyModeTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import Testing
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel DEX-only providers mode", .timeLimit(.minutes(1)))
struct SwapModelDexOnlyModeTests {
    @Test("Legacy restriction hides providers and never reaches the express manager")
    func hideProvidersKeepsLegacyEmptyState() async throws {
        let environment = makeEnvironment(restriction: .hideProviders)
        await environment.expressManager.configure(state: .swap(
            selected: makeProvider(id: "dex", type: .dex, expectAmount: 90),
            providers: makeProviders()
        ))

        let state = try await updateAmountAndWaitForLoadedState(environment: environment)

        guard case .loaded(.swap(.none, let providers), .restriction(.notEnoughBalanceForSwapping, quote: .none)) = state else {
            Issue.record("Expected the legacy empty restriction state, got \(state)")
            return
        }

        #expect(providers.isEmpty)
        #expect(environment.swapModel.expressProviders.isEmpty)
        #expect(!environment.swapModel.isDexOnlyProvidersMode)
        await #expect(environment.expressManager.updateAmountCallsCount == 0)
    }

    @Test("DEX-only mode keeps the restriction state with a quote and exposes only DEX providers")
    func dexOnlyModeExposesOnlyDexProviders() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: dex, providers: makeProviders(dex, cex)))

        let state = try await updateAmountAndWaitForLoadedState(environment: environment)

        guard case .loaded(.swap(.some(let selected), _), .restriction(.notEnoughBalanceForSwapping, quote: .some(let quote))) = state else {
            Issue.record("Expected a restriction state with a quote, got \(state)")
            return
        }

        #expect(selected === dex)
        #expect(quote.expectAmount == 90)
        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex"])
        #expect(environment.swapModel.isDexOnlyProvidersMode)
        #expect(environment.swapModel.receiveAmount.value?.crypto == 90)
    }

    @Test("DEX-only mode treats a dex-bridge provider as DEX")
    func dexOnlyModeKeepsDexBridgeProviders() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let dexBridge = makeProvider(id: "dex-bridge", type: .dexBridge, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: dexBridge, providers: makeProviders(dexBridge, cex)))

        _ = try await updateAmountAndWaitForLoadedState(environment: environment)

        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex-bridge"])
    }

    @Test("DEX-only mode falls back to the legacy empty state when the engine selected a CEX")
    func dexOnlyModeFallsBackWhenEngineSelectedCex() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        // The engine prefers an eligible DEX, so a CEX selection means the pair has no usable DEX
        await environment.expressManager.configure(state: .swap(selected: cex, providers: makeProviders(dex, cex)))

        let state = try await updateAmountAndWaitForLoadedState(environment: environment)

        guard case .loaded(.swap(.none, let providers), .restriction(.notEnoughBalanceForSwapping, quote: .none)) = state else {
            Issue.record("Expected the legacy empty restriction state, got \(state)")
            return
        }

        #expect(providers.isEmpty)
        #expect(environment.swapModel.expressProviders.isEmpty)
    }

    @Test("Best flags are recomputed over the visible DEX providers")
    func dexOnlyModeRecomputesBestFlags() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let bestDex = makeProvider(id: "dex-90", type: .dex, expectAmount: 90)
        let worseDex = makeProvider(id: "dex-85", type: .dex, expectAmount: 85)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)

        // The engine computes the flags over all providers: the hidden CEX is the overall best
        cex.update(isBest: true)
        bestDex.update(isBestDEX: true)

        await environment.expressManager.configure(state: .swap(selected: bestDex, providers: makeProviders(bestDex, worseDex, cex)))

        _ = try await updateAmountAndWaitForLoadedState(environment: environment)

        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex-90", "dex-85"])
        #expect(bestDex.isBest)
        #expect(!bestDex.isBestDEX)
        #expect(!worseDex.isBest)
    }

    @Test("DEX-only mode falls back to the legacy empty state when the pair has no quoted DEX")
    func dexOnlyModeFallsBackWhenNoDexAvailable() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: cex, providers: makeProviders(cex)))

        let state = try await updateAmountAndWaitForLoadedState(environment: environment)

        guard case .loaded(.swap(.none, let providers), .restriction(.notEnoughBalanceForSwapping, quote: .none)) = state else {
            Issue.record("Expected the legacy empty restriction state, got \(state)")
            return
        }

        #expect(providers.isEmpty)
        #expect(environment.swapModel.expressProviders.isEmpty)
    }

    @Test("DEX-only mode falls back to the legacy empty state for a transfer pair")
    func dexOnlyModeFallsBackOnTransferState() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        await environment.expressManager.configure(state: .transfer)

        let state = try await updateAmountAndWaitForLoadedState(environment: environment)

        guard case .loaded(.swap(.none, _), .restriction(.notEnoughBalanceForSwapping, quote: .none)) = state else {
            Issue.record("Expected the legacy empty restriction state, got \(state)")
            return
        }
    }

    @Test("Fallback clears the receive amount left by a previously displayed DEX quote")
    func dexOnlyModeFallbackClearsStaleReceiveAmount() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: dex, providers: makeProviders(dex, cex)))

        _ = try await updateAmountAndWaitForLoadedState(environment: environment)
        #expect(environment.swapModel.receiveAmount.value?.crypto == 90)

        // The DEX drops out (e.g. the edited amount is below its minimum) — only the CEX still quotes
        await environment.expressManager.configure(state: .swap(selected: cex, providers: makeProviders(cex)))

        let state = try await updateAmountAndWaitForLoadedState(environment: environment, amount: 1)

        guard case .loaded(.swap(.none, _), .restriction(.notEnoughBalanceForSwapping, quote: .none)) = state else {
            Issue.record("Expected the legacy empty restriction state, got \(state)")
            return
        }

        #expect(environment.swapModel.receiveAmount.value == nil)
    }

    @Test("Without a balance restriction all provider types stay visible")
    func noRestrictionKeepsAllProviders() async throws {
        let environment = makeEnvironment(restriction: .none)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: dex, providers: makeProviders(dex, cex)))

        _ = try await updateAmountAndWaitForLoadedState(environment: environment)

        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex", "cex"])
        #expect(!environment.swapModel.isDexOnlyProvidersMode)
    }

    @Test("Mode switches off and CEX providers reappear once the wallet is funded")
    func dexOnlyModeLiftsAfterDeposit() async throws {
        let environment = makeEnvironment(restriction: .dexProvidersOnly)
        let dex = makeProvider(id: "dex", type: .dex, expectAmount: 90)
        let cex = makeProvider(id: "cex", type: .cex, expectAmount: 100)
        await environment.expressManager.configure(state: .swap(selected: dex, providers: makeProviders(dex, cex)))

        _ = try await updateAmountAndWaitForLoadedState(environment: environment)
        #expect(environment.swapModel.isDexOnlyProvidersMode)
        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex"])

        environment.balanceRestrictionChecker.result = SwapBalanceRestriction.none

        _ = try await updateAmountAndWaitForLoadedState(environment: environment, amount: 5)
        #expect(!environment.swapModel.isDexOnlyProvidersMode)
        #expect(environment.swapModel.expressProviders.map(\.provider.id) == ["dex", "cex"])
    }
}

// MARK: - Environment

private extension SwapModelDexOnlyModeTests {
    struct Environment {
        let swapModel: SwapModel
        let expressManager: ConfigurableExpressManagerStub
        let balanceRestrictionChecker: BalanceRestrictionCheckerStub
        let sourceToken: SendSwapableToken
    }

    func makeEnvironment(restriction: SwapBalanceRestriction) -> Environment {
        let expressManager = ConfigurableExpressManagerStub()
        let balanceRestrictionChecker = BalanceRestrictionCheckerStub(result: restriction)
        let sourceToken = SwapableTokenStub()

        let swapModel = SwapModel(
            sourceToken: sourceToken,
            receiveToken: nil,
            expressManager: expressManager,
            swapRepository: SwapRepositoryDummy(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryDummy(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: SwapPairUpdateHandlerDummy(),
            balanceRestrictionFeatureChecker: balanceRestrictionChecker,
            shouldStartInitialLoading: false
        )

        return Environment(
            swapModel: swapModel,
            expressManager: expressManager,
            balanceRestrictionChecker: balanceRestrictionChecker,
            sourceToken: sourceToken
        )
    }

    /// The suite `timeLimit` trait guards against a state that never arrives.
    func updateAmountAndWaitForLoadedState(
        environment: Environment,
        amount: Decimal = 10
    ) async throws -> SwapModel.ProvidersState {
        let states = AsyncStream<SwapModel.ProvidersState> { continuation in
            // `statePublisher` replays the current value — drop it so a stale `.loaded` isn't returned
            let cancellable = environment.swapModel.statePublisher.dropFirst().sink { state in
                continuation.yield(state)
            }
            continuation.onTermination = { _ in cancellable.cancel() }
        }

        environment.swapModel.update(sourceAmount: SendAmount(type: .typical(crypto: amount, fiat: nil)))

        for await state in states {
            if case .loaded = state {
                return state
            }
        }

        throw StreamEndedError()
    }

    struct StreamEndedError: Error {}
}

// MARK: - Providers factory

private extension SwapModelDexOnlyModeTests {
    func makeProviders(_ providers: ExpressAvailableProvider...) -> ExpressManagerState.Providers {
        ExpressManagerState.Providers(float: providers, fixed: [])
    }

    func makeProvider(id: String, type: ExpressProviderType, expectAmount: Decimal) -> ExpressAvailableProvider {
        let provider = ExpressProvider(
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

        let quote = ExpressQuote(fromAmount: 10, expectAmount: expectAmount, allowanceContract: nil, quoteId: nil, txType: nil)

        let context = ExpressProviderFlowContext(
            provider: provider,
            pair: ExpressManagerSwappingPair(source: ExpressWalletDummy(), destination: ExpressWalletDummy()),
            rateType: .float,
            expressFeeProvider: ExpressFeeProviderDummy(),
            expressAPIProvider: ExpressAPIProviderStub(),
            mapper: ExpressManagerMapper(),
            featureFlags: ExpressFeatureFlags()
        )

        return ExpressAvailableProvider(
            context: context,
            manager: ExpressProviderManagerStub(state: .restriction(.insufficientBalance(10), quote: quote))
        )
    }
}

// MARK: - Stubs

private final class BalanceRestrictionCheckerStub: SwapBalanceRestrictionFeatureChecker, @unchecked Sendable {
    var result: SwapBalanceRestriction

    init(result: SwapBalanceRestriction) {
        self.result = result
    }

    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction {
        result
    }
}

private actor ConfigurableExpressManagerStub: ExpressManager {
    private var state: ExpressManagerState = .idle
    private(set) var updateAmountCallsCount = 0
    private var amountType: ExpressAmountType?

    func configure(state: ExpressManagerState) {
        self.state = state
    }

    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { amountType }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState { state }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        self.amountType = amountType
        updateAmountCallsCount += 1
        return state
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState { state }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState { state }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState { state }

    func requestData() async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}

private final class ExpressProviderManagerStub: ExpressProviderManager {
    private let state: ExpressProviderManagerState

    init(state: ExpressProviderManagerState) {
        self.state = state
    }

    func getState() -> ExpressProviderManagerState { state }
    func reset() {}
    func update(request: ExpressManagerSwappingPairRequest) async {}

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        fatalError("Not used in tests")
    }
}

private final class SwapableTokenStub: SendSwapableToken {
    private let inner = SendSourceTokenStub()

    // MARK: - SendSourceToken proxy

    var tokenItem: TokenItem { inner.tokenItem }
    var isCustom: Bool { inner.isCustom }
    var fiatItem: FiatItem { inner.fiatItem }
    var userWalletInfo: UserWalletInfo { inner.userWalletInfo }
    var id: WalletModelId { inner.id }
    var header: TokenHeader { inner.header }
    var feeTokenItem: TokenItem { inner.feeTokenItem }
    var defaultAddressString: String { inner.defaultAddressString }
    var availableBalanceProvider: TokenBalanceProvider { inner.availableBalanceProvider }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { inner.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { inner.allowanceService }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { inner.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { inner.emailDataCollectorBuilder }
    var transactionHistoryEnricher: TransactionHistoryExpressDataEnriching? { get async { await inner.transactionHistoryEnricher } }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { inner.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { inner.accountModelAnalyticsProvider }
    var tangemIconProvider: any TangemIconProvider { inner.tangemIconProvider }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { inner.confirmTransactionPolicy }

    // MARK: - Unused in tests

    var isExemptFee: Bool { false }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swap }
    var supportedProvidersFilter: SupportedProvidersFilter { .swap }
    var swapAvailabilityProvider: any SwapAvailabilityProvider { fatalError("Unused in tests") }
    var sendingRestrictionsProvider: any SendingRestrictionsProvider { fatalError("Unused in tests") }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager { fatalError("Unused in tests") }
    var transactionValidator: any SendTransactionValidator { fatalError("Unused in tests") }
    var transactionCreator: any SendTransactionCreator { fatalError("Unused in tests") }
    var balanceProvider: any TangemExpress.BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any TangemExpress.AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
}

private struct ExpressWalletDummy: ExpressSourceWallet {
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

private struct ExpressFeeProviderDummy: ExpressFeeProvider {
    func feeCurrency() -> ExpressWalletCurrency { fatalError("Not used in tests") }
    func feeCurrencyBalance() throws -> Decimal { fatalError("Not used in tests") }
    func estimatedFee(amount: Decimal) async throws -> BSDKFee { fatalError("Not used in tests") }
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(approveData: BSDKApproveTransactionData) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee { fatalError("Not used in tests") }
    func transactionFee(data: ExpressTransactionDataType, allowanceOverride: AllowanceOverride, approveData: BSDKApproveTransactionData) async throws -> ApproveWithSwapFee { fatalError("Not used in tests") }
    func revokeAndApproveTransactionFee(revokeData: BSDKApproveTransactionData) async throws -> RevokeAndApproveFee { fatalError("Not used in tests") }
}

private final class SwapPairUpdateHandlerDummy: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class SwapRepositoryDummy: SwapRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {}
    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {}
    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] { [] }
    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] { [] }
    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider] { [] }
    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}
    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] { [] }
}

private final class ExpressPendingTransactionRepositoryDummy: ExpressPendingTransactionRepository {
    var transactions: [ExpressPendingTransactionRecord] { [] }
    var transactionsPublisher: AnyPublisher<[ExpressPendingTransactionRecord], Never> { .just(output: []) }
    func updateItems(_ items: [ExpressPendingTransactionRecord]) {}
    func swapTransactionDidSend(_ transaction: SentSwapTransactionData) {}
    func hideSwapTransaction(with id: String) {}
}
