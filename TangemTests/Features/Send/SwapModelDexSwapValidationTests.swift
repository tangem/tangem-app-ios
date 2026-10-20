//
//  SwapModelDexSwapValidationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemFoundation
import Testing
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel DEX swap validation", .timeLimit(.minutes(1)))
struct SwapModelDexSwapValidationTests {
    @Test("A destination that requires a memo blocks the swap")
    func memoRequiredDestinationBlocksTheSwap() async throws {
        let sut = makeSUT(receiveToken: makeReceiveToken(destination: .memoRequiredWithoutTag))

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.validationError(error: .destinationMemoRequired), _) = state else {
            Issue.record("Expected the memo restriction, got \(state)")
            return
        }
    }

    @Test("A receive amount below the destination minimum blocks the swap")
    func receiveAmountBelowTheMinimumBlocksTheSwap() async throws {
        let sut = makeSUT(
            receiveToken: makeReceiveToken(restriction: .notEnoughReceivedAmount(minAmount: .fiatUSD(5), reason: .receivingMinimum))
        )

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.notEnoughReceivedAmount(let minAmount, _, let reason), _) = state else {
            Issue.record("Expected the minimum received amount restriction, got \(state)")
            return
        }

        #expect(minAmount == .fiatUSD(5))
        #expect(reason == .receivingMinimum)
    }

    @Test("A destination without a trustline blocks the swap")
    func missingTrustlineBlocksTheSwap() async throws {
        let sut = makeSUT(receiveToken: makeReceiveToken(restriction: .requiresTrustline))

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.trustlineRequired, _) = state else {
            Issue.record("Expected the trustline restriction, got \(state)")
            return
        }
    }

    @Test("A receive amount below a receive-only destination's minimum blocks the swap")
    func receiveAmountBelowAReceiveOnlyDestinationMinimumBlocksTheSwap() async throws {
        let sut = makeSUT(
            receiveToken: makeReceiveOnlyToken(restriction: .notEnoughReceivedAmount(minAmount: .fiatUSD(5), reason: .receivingMinimum))
        )

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.notEnoughReceivedAmount(let minAmount, _, let reason), _) = state else {
            Issue.record("Expected the minimum received amount restriction, got \(state)")
            return
        }

        #expect(minAmount == .fiatUSD(5))
        #expect(reason == .receivingMinimum)
    }

    @Test("A receive-only destination without a trustline blocks the swap")
    func receiveOnlyDestinationWithoutTrustlineBlocksTheSwap() async throws {
        let receiveToken = makeReceiveOnlyToken(restriction: .requiresTrustline)
        let sut = makeSUT(receiveToken: receiveToken)

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.trustlineRequired(let destination), _) = state else {
            Issue.record("Expected the trustline restriction, got \(state)")
            return
        }

        #expect(destination.tokenItem == receiveToken.tokenItem)
    }

    @Test("The DEX preview is validated as a transaction the provider has built")
    func dexPreviewIsValidatedAsAProviderTransaction() async throws {
        let validator = BuilderSpyTransactionValidator()
        let sut = makeSUT(transactionValidator: validator)

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        #expect(validator.builders == [.provider])

        guard case .readyToSwap = state else {
            Issue.record("Expected the swap to stay available, got \(state)")
            return
        }
    }

    @Test("Every other swap is validated as our own transaction")
    func everyOtherSwapIsValidatedAsOurOwnTransaction() async throws {
        let validator = BuilderSpyTransactionValidator()
        let sut = makeSUT(transactionValidator: validator)

        _ = try await sut.validate(amount: makeAmount(), fee: makeFee(), quote: makeQuote())

        #expect(validator.builders == [.wallet])
    }

    @Test("A restriction raised by the validator blocks the swap")
    func restrictionFromTheValidatorBlocksTheSwap() async throws {
        let validator = BuilderSpyTransactionValidator(error: ValidationError.totalExceedsBalance)
        let sut = makeSUT(transactionValidator: validator)

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.notEnoughBalanceForSwapping, _) = state else {
            Issue.record("Expected the balance restriction, got \(state)")
            return
        }
    }
}

// MARK: - SUT

private extension SwapModelDexSwapValidationTests {
    func makeSUT(
        receiveToken: SendReceiveToken? = nil,
        transactionValidator: SendTransactionValidator = BuilderSpyTransactionValidator()
    ) -> SwapModel {
        let sourceToken = SwapableTokenStub(blockchain: .bitcoin(testnet: false), transactionValidator: transactionValidator)

        return SwapModel(
            parameters: PredefinedSwapParameters(
                userWalletInfo: sourceToken.userWalletInfo,
                source: .resolved(sourceToken),
                receive: .resolved(receiveToken ?? makeReceiveToken())
            ),
            expressManager: ExpressManagerDummy(),
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: PairUpdateHandlerDummy(),
            balanceRestrictionFeatureChecker: BalanceRestrictionCheckerDummy(),
            initialResolvingPolicy: .disabled
        )
    }

    func makeReceiveToken(
        restriction: ReceivedRestriction? = nil,
        destination: SendReceiveTokenDestination? = nil
    ) -> SendReceiveToken {
        let tokenItem = TokenItem.accountToken(symbol: "USDT", contract: "0xUSDT")

        // A receive token without a `currencyId` keeps the price impact calculator, which runs before the
        // validation under test, from reaching the quotes repository over the network.
        #expect(tokenItem.currencyId == nil)

        return SwapableTokenStub(
            tokenItem: tokenItem,
            receivingRestriction: restriction,
            destination: destination
        )
    }

    func makeReceiveOnlyToken(restriction: ReceivedRestriction) -> ReceiveOnlyTokenStub {
        ReceiveOnlyTokenStub(
            tokenItem: TokenItem.accountToken(symbol: "USDT", contract: "0xUSDT"),
            restriction: restriction
        )
    }

    func makeProvider() -> ExpressAvailableProvider {
        ExpressAvailableProviderFixture.make(state: .idle)
    }

    func makeDexPreview() -> ExpressProviderManagerState.DEXPreview {
        ExpressProviderManagerState.DEXPreview(
            provider: makeProvider().provider,
            data: ExpressTransactionDataFixture.make(
                fromAmount: Constants.fromAmount,
                toAmount: Constants.expectAmount,
                txValue: Constants.fromAmount,
                txData: "cHNidP8="
            ),
            fee: makeFee(),
            quote: ExpressQuoteFixture.make(fromAmount: Constants.fromAmount, expectAmount: Constants.expectAmount)
        )
    }

    func makeAmount() -> Amount {
        Amount(with: .bitcoin(testnet: false), type: .coin, value: Constants.fromAmount)
    }

    func makeFee() -> Fee {
        Fee(Amount(with: .bitcoin(testnet: false), type: .coin, value: Constants.fee))
    }

    func makeQuote() -> SwapModel.Quote {
        SwapModel.Quote(
            fromAmount: Constants.fromAmount,
            expectAmount: Constants.expectAmount,
            highPriceImpact: nil
        )
    }

    enum Constants {
        static let fromAmount: Decimal = 1
        static let expectAmount: Decimal = 2
        static let fee = Decimal(stringValue: "0.0001")!
    }
}

// MARK: - Fixtures

private extension SendReceiveTokenDestination {
    static var memoRequiredWithoutTag: SendReceiveTokenDestination {
        SendReceiveTokenDestination(
            destination: .resolved(address: "address", resolved: "resolved", memoRequired: true),
            destinationTag: nil
        )
    }
}

// MARK: - Stubs

private final class ReceiveOnlyTokenStub: SendSourceTokenStub {
    private let restriction: ReceivedRestriction

    init(tokenItem: TokenItem, restriction: ReceivedRestriction) {
        self.restriction = restriction
        super.init(tokenItem: tokenItem)
    }

    override var receivingRestrictionsProvider: any ReceivingRestrictionsProvider {
        ReceivingRestrictionsProviderStub(result: restriction)
    }
}

private final class BuilderSpyTransactionValidator: SendTransactionValidator {
    private let error: Error?
    private let state = OSAllocatedUnfairLock(initialState: [SendTransactionBuilder]())

    var builders: [SendTransactionBuilder] { state.withLock { $0 } }

    init(error: Error? = nil) {
        self.error = error
    }

    func validate(amount: Amount) throws {}

    func validate(amount: Amount, fee: Fee) throws {
        try throwIfNeeded()
    }

    func validate(amount: Amount, fee: Fee, builtBy: SendTransactionBuilder) throws {
        state.withLock { $0.append(builtBy) }
        try throwIfNeeded()
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try throwIfNeeded()
    }

    private func throwIfNeeded() throws {
        if let error {
            throw error
        }
    }
}

private actor ExpressManagerDummy: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { nil }
    func getSlippage() -> Decimal? { nil }
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState { .idle }
    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState { .idle }
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState { .idle }
    func update(slippage: Decimal?) async -> ExpressManagerState { .idle }
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState { .idle }
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState { .idle }

    func requestData() async throws -> ExpressTransactionData {
        fatalError("Unused in tests")
    }
}

private final class PairUpdateHandlerDummy: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class BalanceRestrictionCheckerDummy: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}
